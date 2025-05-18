//
//  ComposePostView.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 17/04/24.
//

import SwiftUI

struct ComposePostView: View {
    
    let maxLength: Int
    let isCameraEnabled: Bool
    @Binding var text: String
    @Binding var isLocationVisible: Bool
    @Binding var isSettingsExpanded: Bool
    @Binding var image: UIImage?
    @Binding var isCameraDisplayed: Bool
    @Binding var tag: PostTag
    
    @EnvironmentObject var authVM: AuthenticationViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Header()
            
            PostText()
            
            Footer()
        }
        .padding()
        .onAppear {
            isFocused = true
        }
    }
    
    //MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            ProfilePic()
            
            VStack(alignment: .leading) {
                Text(authVM.username)
                    .fontWeight(.semibold)
                
                Location()
            }
        }
    }
    
    //MARK: - Profile Pic
    
    @ViewBuilder
    private func ProfilePic() -> some View {
        if let imageURL = authVM.profilePic {
            URLNotTapableImageView(imageURL: imageURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
        }
    }
    
    //MARK: - Location
    
    @ViewBuilder
    private func Location() -> some View {
        if isLocationVisible {
            Button {
                withAnimation {
                    isLocationVisible.toggle()
                }
                
            } label: {
                Label(
                    title: { Text("Show me on map") },
                    icon: { Image(systemName: "map") }
                )
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                withAnimation {
                    isLocationVisible.toggle()
                }
            } label: {
                Label(
                    title: { Text("Don't show me on map") },
                    icon: { Image(systemName: "mappin.slash") }
                )
            }
            .buttonStyle(.bordered)
        }
    }
    
    //MARK: - Post Text
    
    @ViewBuilder
    private func PostText() -> some View {
        TextField("What's going on around you?", text: $text, axis: .vertical)
            .focused($isFocused)
            .lineLimit(3...4)
            .onChange(of: text) { newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }
    
    //MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        VStack(spacing: 0) {
            HStack {
                ImagePreview()
                
                Spacer()
                
                Camera()
            }
            .padding(.bottom)
            
            Disclaimer()
            
//            Chevron()
            
//            if isSettingsExpanded {
                ExpandedPostSettings(maxPostLength: maxLength, text: $text, selectedPostTag: $tag, isExpanded: $isSettingsExpanded)
                .padding(.top)
//            } else {
//                CompactedPostSettings(maxPostLength: maxLength, text: $text, selectedPostTag: $tag, isExpanded: $isSettingsExpanded)
//            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    //MARK: - Image Preview
    
    @ViewBuilder
    private func ImagePreview() -> some View {
        if let selectedImage =  image {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(8)
                
                Button {
                    image = nil
                } label: {
                    Image(systemName: "x.circle")
                        .foregroundStyle(.white)
                        .background(Circle().fill(.gray))
                }
                .padding([.top, .trailing], 2)
            }
        }
    }
    
    //MARK: - Camera
    
    @ViewBuilder
    private func Camera() -> some View {
        Image(systemName: "camera.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44, alignment: .center)
            .foregroundStyle(isCameraEnabled ? .blue : .gray)
            .background(
                Circle()
                    .frame(width: 44, height: 44, alignment: .center)
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 5, x: 1, y: 1)
                    .opacity(isCameraEnabled ? 1 : 0.5)
            )
            .disabled(isCameraEnabled)
            .opacity(isCameraEnabled ? 1 : 0.5)
            .onTapGesture {
                if isCameraEnabled {
                    isCameraDisplayed = true
                } else {
                    hapticFeedback(style: .soft)
                }
            }
    }
    
    // MARK: - Disclaimer
    
    @ViewBuilder
    private func Disclaimer() -> some View {
        Label(
            "Posts are shown only to those around you.",
            systemImage: "info.circle"
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.gray)
        .italic()
        .font(.footnote)
    }
    
    //MARK: - Chevron
    
    @ViewBuilder
    private func Chevron() -> some View {
        Image(systemName: isSettingsExpanded ? "chevron.compact.down" : "chevron.compact.up")
            .resizable()
            .foregroundStyle(.gray)
            .scaledToFit()
            .frame(width: 32, height: 12)
            .onTapGesture {
                hapticFeedback(style: .light)
                withAnimation {
                    isSettingsExpanded.toggle()
                }
            }
    }
}

//#Preview {
//    ComposePostView(maxLength: 150, isCameraEnabled: true, text: .constant(""), isLocationVisible: .constant(false), isSettingsExpanded: .constant(true), image: .constant(nil), isCameraDisplayed: .constant(false), tag: .constant(.bored))
//        .environmentObject(AuthenticationViewModel())
//}
