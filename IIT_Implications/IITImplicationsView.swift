//
//MIT License
//
//Copyright © 2025 Cong Le
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  IITImplicationsView.swift
//  IIT_Implications
//
//  Created by Cong Le on 6/30/25.
//


import SwiftUI
import Combine

// MARK: - Core Data Models for IIT Simulation

/// An enumeration representing the architectural style of a system.
/// This directly influences the system's capacity for information integration.
enum SystemArchitecture: String, CaseIterable, Identifiable {
    case integrated = "Integrated (Thalamocortical-like)"
    case modular = "Modular (Cerebellum-like)"
    case random = "Random"
    
    var id: String { self.rawValue }
}

/// Represents a single element within a system, such as a neuron or a silicon gate.
/// In IIT, the nature of the element is irrelevant; only its causal relationships matter.
struct NeuralElement: Identifiable, Equatable {
    let id = UUID()
    var position: CGPoint
    var isActive: Bool = false
}

/// Represents a system of interconnected elements, a potential "complex" in IIT.
/// This model simulates the core properties needed to conceptually evaluate consciousness.
struct SystemComplex: Identifiable {
    let id = UUID()
    var elements: [NeuralElement]
    var connectivity: [UUID: [UUID]] // Adjacency list for connections
    var architecture: SystemArchitecture
    
    /// The simulated value of integrated information (Φ, pronounced "Phi").
    ///
    /// In a real-world application, calculating Φ is computationally immense. Here, we assign a conceptual
    /// value based on the system's architecture to illustrate the theory's principles.
    /// An integrated architecture has a high Φ, whereas a modular one consists of multiple subsystems
    /// with low individual Φ values.
    ///
    /// - Citation: Tononi, Giulio, and Olaf Sporns. 2003. “Measuring Information Integration.”
    ///   *BMC Neuroscience* 4 (1): 31. https://doi.org/10.1186/1471-2202-4-31.
    var phiValue: Double {
        switch architecture {
        case .integrated:
            // High integration leads to a high Φ value. The system is irreducible.
            return 74.5
        case .modular:
            // Modular systems are highly decomposable, leading to a very low Φ for the system as a whole.
            return 3.2
        case .random:
            // Random connectivity lacks the specialized structure for high integration.
            return 12.8
        }
    }
}

// MARK: - ViewModel (MVVM Architecture)

/// Manages the state and logic for the IIT simulation view.
/// This follows best practices by separating view logic from the view itself.
@MainActor
class IITViewModel: ObservableObject {
    
    @Published var mainComplex: SystemComplex
    @Published var selectedArchitecture: SystemArchitecture = .integrated
    
    // Toggles to demonstrate independence from higher-order functions
    @Published var hasLanguageModule: Bool = false
    @Published var hasSelfModel: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with a default integrated system
        self.mainComplex = IITViewModel.createSystem(for: .integrated)
        
        // Listen for changes in the architecture selection
        $selectedArchitecture
            .sink { [weak self] newArchitecture in
                self?.updateSystem(for: newArchitecture)
            }
            .store(in: &cancellables)
    }
    
    /// Updates the main complex based on the selected architecture.
    /// This simulates transitions between different types of systems (e.g., a brain vs. an artifact).
    func updateSystem(for architecture: SystemArchitecture) {
        self.mainComplex = IITViewModel.createSystem(for: architecture)
    }
    
    /// A static factory method to generate different system complexes for the simulation.
    static func createSystem(for architecture: SystemArchitecture) -> SystemComplex {
        let numElements = 16
        var elements = [NeuralElement]()
        var connectivity = [UUID: [UUID]]()
        
        // Arrange elements in a grid for visualization
        for i in 0..<numElements {
            let row = i / 4
            let col = i % 4
            let point = CGPoint(x: 50 + col * 70, y: 50 + row * 70)
            elements.append(NeuralElement(position: point))
        }
        
        for element in elements {
            connectivity[element.id] = []
        }
        
        switch architecture {
        case .integrated:
            // Creates a "small-world" network, simulating a thalamocortical system.
            // Each element connects to its neighbors and has some long-range connections,
            // fostering both functional specialization and integration.
            for i in 0..<numElements {
                // Local connections
                if (i % 4) != 3 { connect(&connectivity, from: elements[i], to: elements[i+1]) } // Right
                if i < 12 { connect(&connectivity, from: elements[i], to: elements[i+4]) } // Down
                // Long-range connections
                if i == 0 { connect(&connectivity, from: elements[i], to: elements[15]) }
                if i == 3 { connect(&connectivity, from: elements[i], to: elements[12]) }
            }
            
        case .modular:
            // Creates distinct modules with strong internal connections but weak external ones.
            // This simulates a cerebellum-like architecture, which according to IIT,
            // does not support a high level of unified consciousness.
            for i in 0..<4 { // Module 1 (Top-left)
                for j in i+1..<4 { connect(&connectivity, from: elements[i], to: elements[j]) }
            }
            for i in 12..<16 { // Module 2 (Bottom-right)
                for j in i+1..<16 { connect(&connectivity, from: elements[i], to: elements[j]) }
            }
            // A single weak link between modules
            connect(&connectivity, from: elements[3], to: elements[12])

        case .random:
            // Random connections. Lacks the specific structure that maximizes integration.
            for i in 0..<numElements {
                let targetIndex = Int.random(in: 0..<numElements)
                if i != targetIndex {
                    connect(&connectivity, from: elements[i], to: elements[targetIndex])
                }
            }
        }
        
        return SystemComplex(elements: elements, connectivity: connectivity, architecture: architecture)
    }
    
    /// Helper to create bidirectional connections.
    private static func connect(_ connectivity: inout [UUID: [UUID]], from e1: NeuralElement, to e2: NeuralElement) {
        connectivity[e1.id]?.append(e2.id)
        connectivity[e2.id]?.append(e1.id)
    }
}

// MARK: - SwiftUI View Implementation

struct IITImplicationsView: View {
    
    @StateObject private var viewModel = IITViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // --- HEADER ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Information Integration Theory: Implications")
                        .font(.largeTitle).bold()
                    
                    Text("An interactive simulation exploring the core claims of IIT. Change the system's architecture and modules to see how its capacity for consciousness (Φ) is affected.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Citation: Tononi, Giulio. 2004. “An Information Integration Theory of Consciousness.” *BMC Neuroscience* 5 (1): 42.")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // --- VISUALIZATION CANVAS ---
                ZStack {
                    SystemComplexView(complex: viewModel.mainComplex)
                        .frame(height: 350)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4), lineWidth: 1))
                    
                    // Overlay for optional modules
                    if viewModel.hasLanguageModule {
                        ModuleView(label: "Language Module", position: .bottomLeading)
                    }
                    if viewModel.hasSelfModel {
                        ModuleView(label: "Self-Model Module", position: .bottomTrailing)
                    }
                }
                .padding(.horizontal)
                
                
                // --- DATA DISPLAY ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Properties")
                        .font(.title2).bold()
                    
                    HStack {
                        Text("Architecture:")
                            .fontWeight(.semibold)
                        Text(viewModel.mainComplex.architecture.rawValue)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Integrated Information (Φ):")
                            .fontWeight(.semibold)
                        Text(String(format: "%.1f", viewModel.mainComplex.phiValue))
                            .font(.system(.title3, design: .monospaced).bold())
                            .foregroundColor(phiColor(viewModel.mainComplex.phiValue))
                        Spacer()
                        Text("(Conceptual Value)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // --- IMPLICATION 1: GRADED CONSCIOUSNESS ---
                    Text("Implication: Consciousness is Graded")
                        .font(.headline).padding(.top)
                    Text("IIT proposes that consciousness is not all-or-nothing but exists in degrees, measured by Φ. An integrated system (like the thalamocortical system) has high Φ, while a modular system (like the cerebellum) has very low Φ.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                
                // --- CONTROL PANEL ---
                 VStack(alignment: .leading, spacing: 15) {
                    Text("Control Panel")
                        .font(.title2).bold()
                    
                    Picker("System Architecture", selection: $viewModel.selectedArchitecture) {
                        ForEach(SystemArchitecture.allCases) { arch in
                            Text(arch.rawValue).tag(arch)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // --- IMPLICATION 2: INDEPENDENCE FROM HIGHER COGNITION ---
                    Text("Implication: Independence from Higher Cognition")
                         .font(.headline).padding(.top, 10)
                    Text("IIT predicts consciousness does not require language or a self-model. These can be informationally-insulated 'modules' that do not contribute to the main complex's Φ value.")
                        .font(.footnote).foregroundColor(.secondary)
                     
                     Text("Citation: This concept aligns with the properties of the 'dynamic core.' Tononi, Giulio, and Gerald M. Edelman. 1998. “Consciousness and Complexity.” *Science* 282 (5395): 1846–51.")
                         .font(.caption).italic().foregroundColor(.gray)

                    Toggle("Enable Language Module", isOn: $viewModel.hasLanguageModule)
                    Toggle("Enable Self-Model Module", isOn: $viewModel.hasSelfModel)
                    
                    // --- IMPLICATION 3: CONSCIOUS ARTIFACTS ---
                    Text("Implication: Conscious Artifacts are Possible")
                        .font(.headline).padding(.top, 10)
                    Text("Since consciousness depends on causal structure (Φ), not substrate, it's theoretically possible to build conscious artifacts from non-biological components like silicon.")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
            }
            .padding(.vertical)
        }
    }
    
    /// Returns a color based on the Φ value to give visual feedback.
    private func phiColor(_ value: Double) -> Color {
        if value > 50 { return .green }
        if value > 10 { return .orange }
        return .red
    }
}


// MARK: - Subviews for Visualization

/// A view that renders the system of elements and their connections using a Canvas.
struct SystemComplexView: View {
    let complex: SystemComplex
    
    var body: some View {
        Canvas { context, size in
            // Draw connections first, so they appear underneath the elements
            for (elementID, connectedIDs) in complex.connectivity {
                if let fromElement = complex.elements.first(where: { $0.id == elementID }) {
                    for connectedID in connectedIDs {
                        if let toElement = complex.elements.first(where: { $0.id == connectedID }) {
                            var path = Path()
                            path.move(to: fromElement.position)
                            path.addLine(to: toElement.position)
                            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1.5)
                        }
                    }
                }
            }
            
            // Draw each element
            for element in complex.elements {
                let rect = CGRect(x: element.position.x - 10, y: element.position.y - 10, width: 20, height: 20)
                let color: Color = element.isActive ? .blue : .black.opacity(0.8)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.5)), lineWidth: 2)
            }
        }
        .animation(.easeInOut, value: complex.id)
    }
}

/// A view representing an informationally insulated module.
struct ModuleView: View {
    let label: String
    let position: Alignment
    
    var body: some View {
        VStack {
            Image(systemName: "cpu")
                .font(.largeTitle)
            Text(label)
                .font(.caption)
                .padding(4)
                .background(.ultraThinMaterial)
                .cornerRadius(6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 2, dash: [5]))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position)
        .padding()
        .transition(.scale.animation(.spring()))
    }
}


// MARK: - Preview Provider
struct IITImplicationsView_Previews: PreviewProvider {
    static var previews: some View {
        IITImplicationsView()
    }
}
