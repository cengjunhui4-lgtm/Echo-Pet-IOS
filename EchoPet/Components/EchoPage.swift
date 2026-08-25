import SwiftUI

struct EchoPage<Content: View>: View {
    let title: String
    let subtitle: String
    private let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EchoTheme.sectionSpacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(EchoTheme.text)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(EchoTheme.secondaryText)
                }

                content
            }
            .padding(EchoTheme.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, EchoTheme.pagePadding)
        }
        .background {
            ZStack {
                EchoBackgroundView()
                EchoTheme.pageBackdrop
            }
            .ignoresSafeArea()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
