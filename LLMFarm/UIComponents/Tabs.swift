//
//  Tabs.swift
//  LLMFarm
//
//  Created by guinmoon on 18.10.2024.
//

import SwiftUI



struct TabButton: View {
    @Binding var index:Int
    @State var targetIndex:Int
    @State var image:Image?
    @State var text: String?
    
    var body: some View {
        Button(action: {
            index = targetIndex
        }) {
            VStack{
                if image != nil{
                    image!
                        .resizable()
                        .frame(width: 22, height: 22)
                        .padding(.top,4)
                }
                if text != nil {
                    Text(text!).font(.footnote)
                        .padding(.bottom,5)
                }
            }
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            
        }        
        .border(width: index == targetIndex ? 4 : 0, edges: [.bottom], color: .accentColor)
        .padding(.horizontal,1)
    }
}

#if os(macOS)
struct CShape1: Shape {
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath()
        
        // Начальное положение
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.minY))
        
        // Верхняя сторона
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Правая сторона
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - 10))
        
        // Округление нижнего правого угла
        path.appendArc(withCenter: CGPoint(x: rect.maxX - 10, y: rect.maxY - 10), radius: 10, startAngle: 0, endAngle: 90, clockwise: true)
        
        // Нижняя сторона
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Левая сторона и округление верхнего левого угла
        path.line(to: CGPoint(x: rect.minX, y: rect.minY + 10))
        path.appendArc(withCenter: CGPoint(x: rect.minX + 10, y: rect.minY + 10), radius: 10, startAngle: 180, endAngle: 270, clockwise: true)
        
        // Закрытие пути
        path.close()
        
        return Path(path.cgPath)
    }
}



struct CShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath()
        
        // Starting point (bottom left)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Left side
        path.line(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top left to top right with arc
        path.line(to: CGPoint(x: rect.maxX - 25, y: rect.minY))
        path.appendArc(withCenter: CGPoint(x: rect.maxX - 25, y: rect.minY + 25), radius: 25, startAngle: 270, endAngle: 360, clockwise: false)
        
        // Right side from top to bottom with arc
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY - 25))
        path.appendArc(withCenter: CGPoint(x: rect.maxX - 25, y: rect.maxY - 25), radius: 25, startAngle: 0, endAngle: 90, clockwise: false)
        
        // Bottom right to bottom left
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        path.close()
        
        return Path(path.cgPath)
    }
}

extension NSBezierPath {
    /// Преобразуем NSBezierPath в CGPath
    var cgPath: CGPath {
        let path = CGMutablePath()
        let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
        for i in 0..<self.elementCount {
            switch self.element(at: i, associatedPoints: points) {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        points.deallocate()
        return path
    }
}
#else
struct CShape : Shape {
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topRight,.bottomRight], cornerRadii: CGSize(width: 25, height: 25))
        return Path(path.cgPath)
    }
}

struct CShape1 : Shape {
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        
        return Path(path.cgPath)
    }
}
#endif

#if os(macOS)
func topSafeAreaInset() -> CGFloat {
    if let window = NSApp.mainWindow {
        let windowFrame = window.frame
        let screenFrame = window.screen?.visibleFrame
        return (screenFrame?.maxY ?? windowFrame.maxY) - windowFrame.maxY
    }
    
    return 0 // Возвращаем 0, если не можем получить доступ к окну
}

func bottomSafeAreaInset() -> CGFloat {
    guard let window = NSApp.mainWindow else { return 0 }
    
    // Получаем фрейм окна и видимый фрейм экрана
    let windowFrame = window.frame
    guard let screenFrame = window.screen?.visibleFrame else { return 0 }
    
    // Безопасная зона снизу может быть понята как разница между нижними координатами видимого экрана и окна
    return windowFrame.minY - screenFrame.minY
}
#endif

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}
