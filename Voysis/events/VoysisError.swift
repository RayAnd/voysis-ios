public enum VoysisError: Error {
    case permissionNotGrantedError
    case duplicateProcessingRequest
    case serializationError(String)
    case requestEncodingError(String)
    case internalServerError
    case networkError(String)
    case audioSessionError
    case unauthorized
    case unknownError(String?)
    case tokenError

}
