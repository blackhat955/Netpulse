import SwiftUI

struct GradientProgressBar: View {
    let progress: Double
    let colors: [Color]
    var height: CGFloat = 10
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: height / 2)
                .fill(Color.gray.opacity(0.15))
            RoundedRectangle(cornerRadius: height / 2)
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                .frame(width: CGFloat(max(0, min(1, progress))) * UIScreen.main.bounds.width * 0.75)
        }
        .frame(height: height)
    }
}
