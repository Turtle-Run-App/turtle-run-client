import SwiftUI
import PhotosUI

struct ProfileImageUploader: View {
    @Binding var selectedImage: UIImage?
    let size: CGFloat
    
    @State private var selectedItem: PhotosPickerItem?
    
    init(selectedImage: Binding<UIImage?>, size: CGFloat = 120) {
        self._selectedImage = selectedImage
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Profile Image Circle
            Circle()
                .fill(Color.turtleRunTheme.mainColor.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.turtleRunTheme.accentColor, lineWidth: 2)
                )
            // Profile Image or Placeholder
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5)
                    .foregroundColor(Color.turtleRunTheme.textSecondaryColor)
            }
            
            // Upload Button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                
            }
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.turtleRunTheme.accentColor)
                .clipShape(Circle())
                .offset(x: 45, y: 45)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}


#Preview {
    ProfileImageUploader(selectedImage: .constant(nil))
        .padding()
        .background(Color.black)
} 
