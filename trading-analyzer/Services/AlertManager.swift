import SwiftUI

@Observable public class AlertManager: @unchecked Sendable {
    public var isAlertPresented: Bool = false
    public var isAlertPresentedBinding: Binding<Bool> {
        .init(get: { self.isAlertPresented }, set: { self.isAlertPresented = $0 })
    }

    private var error: (any LocalizedError)?
    private var message: String?

    public init() {}

    public var alertTitle: String {
        return "Error"
    }

    public var alertMessage: String {
        error?.errorDescription ?? message ?? "Unknown error"
    }

    public func showAlert(_ error: LocalizedError) {
        self.error = error
        isAlertPresented = true
    }

    public func showAlert(message: String) {
        self.message = message
        isAlertPresented = true
    }

    public func hideAlert() {
        isAlertPresented = false
        error = nil
    }
}
