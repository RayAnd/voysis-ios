internal struct Response<T: ApiResponse>: Codable {
    let entity: T?
    let responseMessage: String?
    let requestId: String?
    let responseCode: Int?
    let notificationType: String?
    var type: String
}

public struct Audio: Codable {
    public let href: String?

    public init(href: String) {
        self.href = href
    }
}

public struct Reply: Codable {
    public let text: String?

    public init(text: String?) {
        self.text = text
    }
}

public struct Links: Codable {
    public let linksSelf, audio: Audio?

    public init(linksSelf: Audio?, audio: Audio?) {
        self.linksSelf = linksSelf
        self.audio = audio
    }

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case audio
    }
}

public protocol ApiResponse: Codable {
}

public struct EmptyResponse: ApiResponse {
    //called when decoding external server response before response type is known
}

public struct QueryResponse: ApiResponse, Codable {
    public let id, locale, conversationId, queryType: String?
    public let audioQuery: AudioQuery?
    public let requestId: String?
    public let _links: Links?
}

public struct StreamResponse<C: Context, E: Entities>: ApiResponse, Codable {
    public let id, locale, conversationId, queryType: String?
    public let audioQuery: AudioQuery?
    public let textQuery: TextQuery?
    public let intent: String?
    public let reply: Reply?
    public let entities: E?
    public let context: C?
    public let _links: Links?

    public init(id: String?,
                locale: String?,
                conversationId: String?,
                queryType: String?,
                audioQuery: AudioQuery?,
                textQuery: TextQuery?,
                intent: String?,
                reply: Reply?,
                entities: E?,
                context: C?,
                _links: Links?) {
        self.id = id
        self.locale = locale
        self.conversationId = conversationId
        self.queryType = queryType
        self.audioQuery = audioQuery
        self.textQuery = textQuery
        self.intent = intent
        self.reply = reply
        self.entities = entities
        self.context = context
        self._links = _links
    }
}

public struct Token: ApiResponse, Codable {
    let expiresAt: String
    let token: String
}
