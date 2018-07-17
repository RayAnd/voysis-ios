import Foundation

/*
 functions manage converting requests/responses into their correct object types
*/
private let serverError = "internal_server_error"
private let queryComplete = "query_complete"
private let notification = "notification"
private let response = "response"
private let vadStop = "vad_stop"

func encodeRequest<C: Context>(text: String? = nil, context: C?, userId : String?, token : String) throws -> String? {
    let requestEntity = getRequestEntity(text, context, userId)
    let request = SocketRequest(entity: requestEntity, method: "POST", headers: Headers(token: token), restURI: "/queries")
    return try encodeRequest(request)
}
func encodeRequest<T>(_ socketRequest: SocketRequest<T>) throws -> String? {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(socketRequest) {
        return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
    }
    throw VoysisError.requestEncodingError
}

func getRequestEntity<C: Context>(_ text: String?, _ context: C?, _ userId: String? ) -> RequestEntity<C> {
    if let queryText = text {
        return RequestEntity(textQuery: TextQuery(text: queryText), queryType: "text", userId: userId, context: context)
    } else {
        return RequestEntity(audioQuery: AudioQuery(), queryType: "audio", userId: userId, context: context)
    }
}

func decodeResponse<C: Context, E: Entities>(json: String, context: C.Type, entity: E.Type) throws -> Event {
    do {
        let internalResponse = try decodeResponse(Response<EmptyResponse>.self, json)
        switch internalResponse.type {
        case response:
            let queryResponse = try decodeResponse(Response<QueryResponse>.self, json)
            return Event(response: queryResponse.entity, type: .audioQueryCreated)
        case notification:
            let type = internalResponse.notificationType!
            if type == vadStop {
                return Event(response: nil, type: .vadReceived)
            } else if type == queryComplete {
                let streamResponse = try decodeResponse(Response<StreamResponse<C, E>>.self, json)
                return Event(response: streamResponse.entity, type: .audioQueryCompleted)
            } else if type == serverError {
                throw VoysisError.internalServerError
            } else {
                throw VoysisError.unknownError
            }
        default:
            throw VoysisError.serializationError(json)
        }
    } catch {
        throw VoysisError.serializationError(json)
    }
}

func decodeResponse<T: Codable>(_ type: T.Type = T.self, _ data: String) throws -> T {
    let decoder = JSONDecoder()
    do {
        return try decoder.decode(type.self, from: data.data(using: .utf8)!)
    } catch {
        throw VoysisError.serializationError(error.localizedDescription)
    }
}
