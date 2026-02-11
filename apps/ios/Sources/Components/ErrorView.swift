import SwiftUI

struct ErrorBanner: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(error.errorDescription ?? "An error occurred")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
            }

            if error.shouldRetry, let onRetry = onRetry {
                Button {
                    onRetry()
                } label: {
                    Text("Retry")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

// View modifier for showing errors
extension View {
    func errorBanner(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        ZStack(alignment: .top) {
            self

            if let err = error.wrappedValue {
                ErrorBanner(
                    error: err,
                    onRetry: onRetry,
                    onDismiss: { error.wrappedValue = nil }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}
