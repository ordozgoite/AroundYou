//
//  CropScreen.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 28/02/24.
//

import SwiftUI

struct CropScreen: View {
    
    let size: CGSize
    var image: UIImage?
    var onCrop: (UIImage?,Bool)->()
    
    /// - View Properties
    @Environment(\.dismiss) private var dismiss
    /// - Gesture Properties
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    var body: some View{
        NavigationStack{
            ImageView()
                .navigationTitle("Crop View")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .background {
                    Color.black
                        .ignoresSafeArea()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            /// Converting View to Image (Native iOS 16+)
                            let renderer = ImageRenderer(content: ImageView(true))
                            renderer.proposedSize = .init(size)
                            if let image = renderer.uiImage{
                                onCrop(image,true)
                            }else{
                                onCrop(nil,false)
                            }
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                    }
                }
        }
    }
    
    /// - Image View
    @ViewBuilder
    func ImageView(_ hideGrids: Bool = false)-> some View {
        let cropSize = size
        GeometryReader{
            let size = $0.size
            
            if let image{
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(content: {
                        GeometryReader { proxy in
                            let rect = proxy.frame(in: .named("CROPVIEW"))
                            
                            Color.clear
                                .onChange(of: isInteracting) { newValue in
                                    /// - true Dragging
                                    /// - false Stopped Dragging
                                    /// With the Help of GeometryReader
                                    /// We can now read the minX,Y and maxX,Y of the Image
                                    if !newValue{
                                        withAnimation(.easeInOut(duration: 0.2)){
                                            if rect.minX > 0{
                                                /// - Resetting to Last Location
                                                hapticFeedback(style: .medium)
                                                offset.width = (offset.width - rect.minX)
                                            }
                                            if rect.minY > 0{
                                                /// - Resetting to Last Location
                                                hapticFeedback(style: .medium)
                                                offset.height = (offset.height - rect.minY)
                                            }
                                            
                                            /// - Doing the Same for maxX,Y
                                            if rect.maxX < size.width{
                                                /// - Resetting to Last Location
                                                hapticFeedback(style: .medium)
                                                offset.width = (rect.minX - offset.width)
                                            }
                                            
                                            if rect.maxY < size.height{
                                                /// - Resetting to Last Location
                                                hapticFeedback(style: .medium)
                                                offset.height = (rect.minY - offset.height)
                                            }
                                        }
                                        
                                        /// - Storing Last Offset
                                        lastStoredOffset = offset
                                    }
                                }
                        }
                    })
                    .frame(width: size.width, height: size.height)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .overlay(content: {
            /// We Don't Need Grid View for Cropped Image
            if !hideGrids{
                Grids()
            }
        })
        .coordinateSpace(name: "CROPVIEW")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let translation = value.translation
                    offset = CGSize(width: translation.width + lastStoredOffset.width, height: translation.height + lastStoredOffset.height)
                })
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let updatedScale = value + lastScale
                    /// - Limiting Beyond 1
                    scale = (updatedScale < 1 ? 1 : updatedScale)
                }).onEnded({ value in
                    withAnimation(.easeInOut(duration: 0.2)){
                        if scale < 1{
                            scale = 1
                            lastScale = 0
                        }else{
                            lastScale = scale - 1
                        }
                    }
                })
        )
        .frame(width: size.width, height: size.height)
        .cornerRadius(size.height / 2)
    }
    
    /// - Grids
    @ViewBuilder
    func Grids()->some View{
        ZStack{
            HStack{
                ForEach(1...5,id: \.self){_ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(width: 1)
                        .frame(maxWidth: .infinity)
                }
            }
            
            VStack{
                ForEach(1...8,id: \.self){_ in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(height: 1)
                        .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

#Preview {
    CropScreen(size: CGSize(width: 300, height: 300), onCrop: {_,_ in })
}
