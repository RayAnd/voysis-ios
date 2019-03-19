import AVFoundation

internal class ServiceImpl: Service {
    private let feedbackManager: FeedbackManager
    private let dispatchQueue: DispatchQueue
    private let tokenManager: TokenManager
    private let audioQueue: OperationQueue
    private let session: AudioSession
    private let recorder: AudioRecorder
    private let client: Client
    private let config: Config

    private var finishedReason: FinishedReason?
    private var byteSender: ByteSender?
    private let maxBytes: Int

    public var state = State.idle

    init(client: Client,
         recorder: AudioRecorder,
         dispatchQueue: DispatchQueue,
         feedbackManager: FeedbackManager,
         tokenManager: TokenManager,
         config: Config,
         session: AudioSession) {
        self.client = client
        self.recorder = recorder
        self.tokenManager = tokenManager
        self.config = config
        self.session = session
        self.dispatchQueue = dispatchQueue
        self.feedbackManager = feedbackManager
        audioQueue = OperationQueue()
        audioQueue.name = "VoysisAudioRequests"
        audioQueue.maxConcurrentOperationCount = 1
        audioQueue.isSuspended = true
        maxBytes = Utils.calculateMaxRecordingLength(Int(session.getNativeSampleRate()))
    }

    public func startAudioQuery<C, E, T: Callback>(context: C?, callback: T) where T.C == C, T.E == E {
        let dispatcher = CallbackDispatcher(dispatchQueue, callback)
        if state != .idle {
            dispatcher.failure(.duplicateProcessingRequest)
            return
        }
        do {
            try session.requestRecordPermission { granted in
                guard granted else {
                    dispatcher.failure(.permissionNotGrantedError)
                    return
                }
                self.performAudioQuery(context, dispatcher)
            }
        } catch {
            dispatcher.failure(.audioSessionError)
        }
    }

    public func sendTextQuery<C, E, T: Callback>(text: String, context: C?, callback: T) where T.C == C, T.E == E {
        let dispatcher = CallbackDispatcher(dispatchQueue, callback)
        if state != .idle {
            dispatcher.failure(.duplicateProcessingRequest)
            return
        }
        self.performTextQuery(text, context, dispatcher)
    }

    public func finish() {
        stop(.manualStop, Data([4]))
    }

    public func cancel() {
        stop(.manualStop)
        client.cancelAudioStream()
        state = .idle
    }

    public func refreshSessionToken(tokenHandler: @escaping TokenHandler, errorHandler: @escaping ErrorHandler) {
        tokenManager.tokenHandler = tokenHandler
        tokenManager.tokenErrorHandler = errorHandler
        do {
            let requestEntity = RequestEntity(userId: config.userId, context: nil as EmptyContext?)
            let request = SocketRequest(entity: requestEntity, method: "POST", headers: Headers(token: tokenManager.refreshToken, xVoysisIgnoreVad: !config.isVadEnabled), restURI: "/tokens")
            let entity = try Converter.encodeRequest(request)
            client.sendString(entity: entity!, onMessage: tokenManager.onTokenMessage, onError: tokenManager.onError)
        } catch {
            if let error = error as? VoysisError {
                tokenManager.onError(error)
            }
        }
    }

    public func sendFeedback(queryId: String, feedback: FeedbackData, feedbackHandler: @escaping FeedbackHandler, errorHandler: @escaping ErrorHandler) {
        feedbackManager.feedbackHandler = feedbackHandler
        feedbackManager.feedbackErrorHandler = errorHandler
        if tokenManager.tokenIsValid() {
            sendFeedback(feedback: feedback, queryId: queryId)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.sendFeedback(feedback: feedback, queryId: queryId) }, errorHandler: feedbackManager.onError)
        }
    }

    private func sendFeedback(feedback: FeedbackData, queryId: String) {
        do {
            let request = SocketRequest(entity: feedback, method: "PATCH", headers: Headers(token: tokenManager.token!.token, xVoysisIgnoreVad: !config.isVadEnabled), restURI: "/queries/\(queryId)/feedback")
            let entity = try Converter.encodeRequest(request)
            client.sendString(entity: entity!, onMessage: feedbackManager.onMessage, onError: feedbackManager.onError)
        } catch {
            if let error = error as? VoysisError {
                feedbackManager.onError(error)
            }
        }
    }

    private func performTextQuery<C: Context, T: Callback>(_ text: String, _ context: C?, _ dispatcher: CallbackDispatcher<T>) {
        state = .processing
        if tokenManager.tokenIsValid() {
            startTextQuery(context, text, dispatcher)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.startTextQuery(context, text, dispatcher) }, errorHandler: { self.onError($0, dispatcher) })
        }
    }

    private func startTextQuery<C: Context, T: Callback>(_ context: C?, _ text: String, _ dispatcher: CallbackDispatcher<T>) {
        do {
            if let request = try Converter.encodeRequest(text: text, context: context, config: config, mimeType: recorder.getMimeType(), token: tokenManager.token!.token) {
                client.sendString(entity: request, onMessage: { self.onTextMessage($0, dispatcher) }, onError: { self.onError($0, dispatcher) })
            }
        } catch {
            onError(error, dispatcher)
        }
    }

    private func performAudioQuery<C: Context, T: Callback>(_ context: C?, _ dispatcher: CallbackDispatcher<T>) {
        state = .recording
        startRecording(dispatcher)
        if tokenManager.tokenIsValid() {
            startAudioQuery(context, dispatcher)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.startAudioQuery(context, dispatcher) }, errorHandler: { self.onError($0, dispatcher) })
        }
    }

    private func startAudioQuery<C: Context, T: Callback>(_ context: C?, _ dispatcher: CallbackDispatcher<T>) {
        do {
            if let request = try Converter.encodeRequest(context: context, config: config, mimeType: recorder.getMimeType(), token: tokenManager.token!.token) {
                byteSender = client.setupAudioStream(entity: request, onMessage: { self.onAudioMessage($0, dispatcher) }, onError: { self.onError($0, dispatcher) })
                audioQueue.isSuspended = false
            }
        } catch {
            onError(error, dispatcher)
        }
    }

    private func startRecording<T: Callback>(_ callback: CallbackDispatcher<T>) {
        audioQueue.cancelAllOperations()
        audioQueue.isSuspended = true
        byteSender = nil
        var bytesRead = 0
        recorder.start {
            self.audioCallback($0, &bytesRead, callback)
        }
        callback.recordingStarted()
    }

    private func audioCallback<T: Callback>(_ data: Data, _ bytesRead: inout Int, _ dispatcher: CallbackDispatcher<T>) {
        guard !data.isEmpty else {
            return
        }
        queueAudio(data)
        dispatcher.audioData(data)
        bytesRead += data.count
        if bytesRead >= maxBytes {
            finish()
        }
        if finishedReason != nil && state == .processing {
            dispatcher.recordingFinished(finishedReason!)
            finishedReason = nil
        }
    }

    private func stop(_ reason: FinishedReason, _ data: Data? = nil) {
        state = .processing
        finishedReason = reason
        recorder.stop()
        queueAudio(data)
    }

    private func queueAudio(_ data: Data?) {
        audioQueue.addOperation {
            if data != nil {
                self.byteSender?(data!)
            }
        }
    }

    private func onError<T: Callback>(_ error: Error, _ dispatcher: CallbackDispatcher<T>) {
        cancel()
        shutDownSession(dispatcher)
        if let error = error as? VoysisError {
            dispatcher.failure(error)
        } else {
            dispatcher.failure(.unknownError(error.localizedDescription))
        }
    }

    private func onAudioMessage<T: Callback>(_ data: String, _ dispatcher: CallbackDispatcher<T>) {
        do {
            let event = try Converter.decodeResponse(json: data, context: T.C.self, entity: T.E.self)
            switch event.type {
            case .vadReceived:
                stop(.vadReceived)
            case .audioQueryCompleted:
                state = .idle
                dispatcher.success(event.response! as! StreamResponse<T.C, T.E>)
                shutDownSession(dispatcher)
            case .audioQueryCreated:
                dispatcher.queryResponse(event.response as! QueryResponse)
            }
        } catch {
            cancel()
            if let error = error as? VoysisError {
                dispatcher.failure(error)
            }
        }
    }

    private func onTextMessage<T: Callback>(_ data: String, _ dispatcher: CallbackDispatcher<T>) {
        do {
            let streamResponse = try Converter.decodeResponse(Response<StreamResponse<T.C, T.E>>.self, data)
            state = .idle
            dispatcher.success(streamResponse.entity!)
        } catch {
            cancel()
            if let error = error as? VoysisError {
                dispatcher.failure(error)
            }
        }
    }

    private func shutDownSession<T: Callback>(_ dispatcher: CallbackDispatcher<T>) {
        do {
            try session.shutDown()
        } catch {
            dispatcher.failure(.audioSessionError)
        }
    }
}
