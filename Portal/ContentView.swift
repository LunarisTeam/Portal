//
//  ContentView.swift
//  Portal
//
//  Created by Marzia Pirozzi on 17/03/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @State private var reality: RealityViewContent?
    
    var body: some View {
        
        
        RealityView { content in
            let world = makeWorld()
            let portal = makePortal(world:world)
            
            content.add(world)
            content.add(portal)
            
            
        } .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
            //should be targeted to the spaceship only
            //but it will be actually triggered by the pinch so it'a fine for now
                .onEnded {
                    $0.entity.applyTapForBehaviors()
                })
        
    }
}
public func makeWorld() -> Entity{
    let world = Entity()
    world.components[WorldComponent.self] = .init()
    
    //World Lighting
    if let environment = try? EnvironmentResource.load(named: "Light"){
        world.components[ImageBasedLightComponent.self] = .init(source: .single(environment),intensityExponent: 2.0)
        world.components[ImageBasedLightReceiverComponent.self] = .init(imageBasedLight: world)
    }
    
    // World Background with Image
    let resource = try! TextureResource.load(named: "SpaceLight")
    var material = UnlitMaterial()
    material.color = .init(texture: .init(resource))
    let background = Entity()
    background.components.set(ModelComponent(
        mesh: .generateSphere(radius: 0.8),
        materials: [material]))
    background.scale.x *= -1
    world.addChild(background)
    
    
    // World Background with Model
    /*if let pokemonCenter = try? Entity.load(named: "Pokemon_Center_Emerald") {
        pokemonCenter.scale = [0.003,0.003,0.003]
        pokemonCenter.position = [0,-0.5,-0.5]
        world.addChild(pokemonCenter)
    }*/
    

    //3D Objects
    if let spaceshipScene = try? Entity.load(named: "Scene", in: realityKitContentBundle) {
        spaceshipScene.scale = [0.4,0.4,0.4]
        spaceshipScene.transform.rotation = simd_quatf(angle: .pi/2, axis: [0,1,0])
        spaceshipScene.position = [0,0,0]
        spaceshipScene.components[PortalCrossingComponent.self] = .init()
        world.addChild(spaceshipScene)
    }
    
    return world
}

public func makePortal(world: Entity) -> Entity {
    let portal = Entity()
    
    // Generate a hexagonal mesh with a rotated orientation
    let hexagonMesh = generateHexagonalMesh(radius: 0.45) // Adjust radius as needed
    let modelComponent = ModelComponent(mesh: hexagonMesh, materials: [PortalMaterial()])
    
    portal.components[ModelComponent.self] = modelComponent
    portal.components[PortalComponent.self] = .init(target: world)
    
    if #available(visionOS 2.0, *) {
        let portalComponent = PortalComponent(
            target: world,
            clippingMode: .disabled,
            crossingMode: .plane(.positiveZ)
        )
        portal.components.set(portalComponent)
    }
    
    return portal
}

// Function to generate a hexagonal mesh rotated by 60 degrees
func generateHexagonalMesh(radius: Float) -> MeshResource {
    let rotationOffset = Float.pi / 6  // 30 degrees in radians to rotate the hexagon
    let vertices: [SIMD3<Float>] = (0..<6).map { i in
        let angle = Float(i) * (Float.pi / 3) + rotationOffset  // Rotate by 30 degrees
        return SIMD3(radius * cos(angle), radius * sin(angle), 0)
    }
    
    let indices: [UInt32] = [
        0, 1, 2,
        2, 3, 4,
        4, 5, 0,
        0, 2, 4
    ]
    
    var meshDescriptor = MeshDescriptor()
    meshDescriptor.positions = MeshBuffer(vertices)
    meshDescriptor.primitives = .triangles(indices)
    
    return try! MeshResource.generate(from: [meshDescriptor])
}


#Preview(windowStyle: .volumetric) {
    ContentView()
}
