import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var pet = Pet()
    @State private var timer: AnyCancellable? = nil
    @State private var isGameStarted: Bool = false // Track if the game has started

    var body: some View {
        ZStack {
            if isGameStarted {
                // Main Game View
                ZStack {
                    // Background Image
                    Image("background") 
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        // Pet's Mood Display with GUI Text Background
                        ZStack {
                            Image("text_bg")
                                .resizable()
                                .frame(width: 200, height: 50)
                            Text("Pet's Mood: \(pet.mood)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        // Pet Image
                        Image(pet.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)

                        // Stats Display
                        VStack(spacing: 10) {
                            statView(label: "Happiness", value: pet.happiness)
                            statView(label: "Energy", value: pet.energy)
                            statView(label: "Hunger", value: pet.hunger)
                            statView(label: "Hydration", value: pet.hydration)
                        }

                        // Action Buttons
                        HStack(spacing: 15) {
                            Button(action: { pet.feed(.snack) }) {
                                Image("button_snack")
                                    .resizable()
                                    .frame(width: 100, height: 50)
                            }
                            Button(action: { pet.feed(.petFood) }) {
                                Image("button_petfood")
                                    .resizable()
                                    .frame(width: 100, height: 50)
                            }
                            Button(action: { pet.feed(.water) }) {
                                Image("button_water")
                                    .resizable()
                                    .frame(width: 100, height: 50)
                            }
                        }

                        Button(action: { pet.play() }) {
                            Image("button_play")
                                .resizable()
                                .frame(width: 200, height: 60)
                        }
                    }
                }
                .onAppear {
                    startTimer()
                }
                .onDisappear {
                    timer?.cancel()
                }
            } else {
                // Start Menu View
                ZStack {
                    // Background Image
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 40) {
                        // Game Logo
                        Image("game_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 150)

                        // Start Game Button
                        Button(action: {
                            isGameStarted = true
                        }) {
                            Image("button_start_game")
                                .resizable()
                                .frame(width: 200, height: 60)
                        }
                    }
                }
            }
        }
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                pet.update()
            }
    }

    private func statView(label: String, value: Int) -> some View {
        ZStack {
            Image("text_bg")
                .resizable()
                .frame(width: 200, height: 40)
            HStack {
                Text("\(label): \(value)%")
                    .foregroundColor(.white)
                    .font(.body)
            }
        }
    }
}

class Pet: ObservableObject {
    enum FoodType {
        case snack, petFood, water
    }

    // Configurable variables
    @Published var happiness: Int = 100
    @Published var energy: Int = 100
    @Published var hunger: Int = 100
    @Published var hydration: Int = 100

    @Published var mood: String = "Happy"
    @Published var imageName: String = "pet_awake" 

    private var isSleeping: Bool = false
    private var lastInteractionTime: Date = Date()

    private let hungerDecayRate: Double = 0.1
    private let hydrationDecayRate: Double = 0.1
    private let happinessDecayRate: Double = 0.1
    private let energyDecayRate: Double = 0.1

    private var hungerDouble: Double = 100
    private var hydrationDouble: Double = 100
    private var happinessDouble: Double = 100
    private var energyDouble: Double = 100

    private let snackHappinessBoost: Int = 5
    private let snackHungerBoost: Int = 10
    private let petFoodHungerBoost: Int = 50
    private let waterHydrationBoost: Int = 50

    func update() {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 21 || hour < 6 {
            sleep()
        } else {
            wakeUp()
        }

        if !isSleeping {
            happinessDouble = max(happinessDouble - happinessDecayRate, 0)
            energyDouble = max(energyDouble - energyDecayRate, 0)
            hungerDouble = max(hungerDouble - hungerDecayRate, 0)
            hydrationDouble = max(hydrationDouble - hydrationDecayRate, 0)

            regenerateEnergy()

            happiness = Int(happinessDouble)
            energy = Int(energyDouble)
            hunger = Int(hungerDouble)
            hydration = Int(hydrationDouble)

            checkHealth()
        }

        updateMood()
    }

    func feed(_ type: FoodType) {
        lastInteractionTime = Date() // Reset interaction timer
        switch type {
        case .snack:
            happinessDouble = min(happinessDouble + Double(snackHappinessBoost), 100)
          // Show pet_eatting image temporarily
            hungerDouble = min(hungerDouble + Double(snackHungerBoost), 100)
            imageName = "pet_eatting"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self.updateImageName()
            }
        case .petFood:
            hungerDouble = min(hungerDouble + Double(petFoodHungerBoost), 100)
          // Show pet_eatting image temporarily
            imageName = "pet_eatting"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self.updateImageName()
            }
        case .water:
            hydrationDouble = min(hydrationDouble + Double(waterHydrationBoost), 100)
          // Show pet_drinking image temporarily
            imageName = "pet_drinking"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              self.updateImageName()
            }
        }
        happiness = Int(happinessDouble)
        hunger = Int(hungerDouble)
        hydration = Int(hydrationDouble)
    }

    func play() {
        lastInteractionTime = Date() // Reset interaction timer
        if !isSleeping {
            happinessDouble = min(happinessDouble + 10, 100)
            energyDouble = max(energyDouble - 10, 0)
            
            // Show pet_happy image temporarily
            imageName = "pet_happy"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.updateImageName()
            }
        }
        happiness = Int(happinessDouble)
        energy = Int(energyDouble)
    }

    private func regenerateEnergy() {
        let inactivityTime = Date().timeIntervalSince(lastInteractionTime)
        if inactivityTime >= 30 { // After N seconds of no interaction
            energyDouble = min(energyDouble + 0.1 / 60, 100) // 0.1 energy per sec
            energy = Int(energyDouble)
            imageName = "pet_sleeping"
        }
    }

    private func sleep() {
        isSleeping = true
        imageName = "pet_sleeping"
        if hunger > 30 && hydration > 30 {
            energyDouble = min(energyDouble + 5, 100) // Energy refills slowly while sleeping
            energy = Int(energyDouble)
        } else {
            wakeUp()
        }
    }

    private func wakeUp() {
        isSleeping = false
        if hunger < 30 || hydration < 30 {
            energyDouble = max(energyDouble - 10, 0)
            energy = Int(energyDouble)
        }
        updateImageName()
    }

    private func checkHealth() {
        if hunger == 0 || hydration == 0 || energy == 0{
            mood = "Dead"
            imageName = "pet_dead"
            happiness = 0
        }
    }

    private func updateMood() {
        if hunger < 30 && hunger > 1{
            mood = "Hungry"
            imageName = "pet_hungry"
        } else if hydration < 30 && hydration > 1{
            mood = "Thirsty"
            imageName = "pet_thirsty" 
        } else if energy < 30 && energy > 1{
            mood = "Tired"
            if imageName != "pet_sleeping"{
              imageName = "pet_tired"
            }
        } else {
            mood = "Happy"
        }
    }

    private func updateImageName() {
        if hunger == 0 || hydration == 0 {
            imageName = "pet_dead"
        } else if isSleeping {
            imageName = "pet_sleeping"
        } else if hunger < 30 {
            imageName = "pet_hungry"
        } else if hydration < 30 {
            imageName = "pet_thirsty"
        } else {
            imageName = "pet_awake"
        }
    }
}

@main
struct RaisingSimsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
