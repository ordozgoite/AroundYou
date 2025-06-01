//
//  RadarBackground.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 01/06/25.
//

import SwiftUI

struct RadarView: View {
    @State private var rotation = Angle.zero
    
    var body: some View {
        GeometryReader { geometry in
            let size = max(geometry.size.width, geometry.size.height) * 1.8
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ForEach(1..<6) { i in
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        .frame(width: size * CGFloat(i) / 5,
                               height: size * CGFloat(i) / 5)
                }
                
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: size * 0.05)
                
                RadarBeam()
                    .frame(width: size, height: size)
                    .rotationEffect(rotation)
                    .blendMode(.plusLighter)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct RadarBeam: View {
    var body: some View {
        RadarSector(startAngle: .degrees(0), endAngle: .degrees(60))
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.3),
                        Color.green.opacity(0.1),
                        .clear
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(60)
                )
            )
    }
}

struct RadarSector: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center,
                    radius: rect.width / 2,
                    startAngle: startAngle - .degrees(90),
                    endAngle: endAngle - .degrees(90),
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview {
    RadarView()
}
