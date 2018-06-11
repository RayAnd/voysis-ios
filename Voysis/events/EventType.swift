internal enum EventType {
    case audioQueryCreated
    case vadReceived
    case audioQueryCompleted
}

public enum FinishedReason {
    case vadReceived
    case manualStop
}