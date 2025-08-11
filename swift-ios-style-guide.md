# Modern iOS Swift Style Guide - Top 10 Rules

## 1. Use Swift's Type Inference and Avoid Redundant Type Annotations

Swift's type inference makes code cleaner and more readable. Only specify types when necessary for clarity or when the compiler requires it.

### ✅ Good Example
```swift
let names = ["Alice", "Bob", "Charlie"]
let count = names.count
let view = UIView()
let isEnabled = true
```

### ❌ Bad Example
```swift
let names: [String] = ["Alice", "Bob", "Charlie"]
let count: Int = names.count
let view: UIView = UIView()
let isEnabled: Bool = true
```

## 2. Prefer `guard` for Early Exit and Unwrapping

Use `guard` statements to handle preconditions and optional unwrapping at the beginning of functions. This reduces nesting and improves readability.

### ✅ Good Example
```swift
func processUser(_ user: User?) {
    guard let user = user else {
        print("No user provided")
        return
    }
    
    guard user.age >= 18 else {
        print("User must be 18 or older")
        return
    }
    
    // Main logic with unwrapped, validated user
    updateProfile(for: user)
}
```

### ❌ Bad Example
```swift
func processUser(_ user: User?) {
    if let user = user {
        if user.age >= 18 {
            // Nested logic
            updateProfile(for: user)
        } else {
            print("User must be 18 or older")
        }
    } else {
        print("No user provided")
    }
}
```

## 3. Use Trailing Closure Syntax for Single/Last Closure Parameters

When a function's last parameter is a closure, use trailing closure syntax for better readability.

### ✅ Good Example
```swift
// Single closure parameter
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 0
}

// Multiple parameters with last being a closure
UIView.animate(withDuration: 0.3, animations: {
    self.view.alpha = 0
}) { finished in
    self.view.removeFromSuperview()
}

// Array operations
let doubled = numbers.map { $0 * 2 }
let evens = numbers.filter { $0 % 2 == 0 }
```

### ❌ Bad Example
```swift
UIView.animate(withDuration: 0.3, animations: {
    self.view.alpha = 0
})

let doubled = numbers.map({ $0 * 2 })
let evens = numbers.filter({ $0 % 2 == 0 })
```

## 4. Use Value Types (Structs) Over Reference Types (Classes) When Possible

Prefer structs for data models and simple types. Use classes only when you need reference semantics, inheritance, or Objective-C interoperability.

### ✅ Good Example
```swift
struct User {
    let id: UUID
    var name: String
    var email: String
}

struct Configuration {
    var apiEndpoint: URL
    var timeout: TimeInterval
    var retryCount: Int
}
```

### ❌ Bad Example
```swift
// Unnecessary use of class for simple data
class User {
    var id: UUID
    var name: String
    var email: String
    
    init(id: UUID, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
```

## 5. Use Extensions to Organize Code Logically

Separate protocol conformances and logical groupings of functionality using extensions. This improves code organization and readability.

### ✅ Good Example
```swift
class ProfileViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var users: [User] = []
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Cell configuration
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle selection
    }
}

// MARK: - Private Methods
private extension ProfileViewController {
    func loadUsers() {
        // Load users
    }
}
```

### ❌ Bad Example
```swift
class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var users: [User] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Everything mixed together
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // No logical separation
    }
    
    private func loadUsers() {
        // Private methods mixed with protocol methods
    }
}
```

## 6. Use Weak/Unowned References to Avoid Retain Cycles

Always use `[weak self]` or `[unowned self]` in closures to prevent retain cycles, especially in completion handlers and animations.

### ✅ Good Example
```swift
class DataManager {
    func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
        networkClient.request(endpoint: .users) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                self.processData(data)
                completion(.success(data))
            case .failure(let error):
                self.handleError(error)
                completion(.failure(error))
            }
        }
    }
}

// Using unowned when you're certain self won't be nil
class TimerViewController: UIViewController {
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            self.updateUI()
        }
    }
}
```

### ❌ Bad Example
```swift
class DataManager {
    func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
        networkClient.request(endpoint: .users) { result in
            // Strong reference to self - potential retain cycle
            switch result {
            case .success(let data):
                self.processData(data)
                completion(.success(data))
            case .failure(let error):
                self.handleError(error)
                completion(.failure(error))
            }
        }
    }
}
```

## 7. Use `async/await` for Asynchronous Code (iOS 13+)

Modern Swift uses async/await for cleaner asynchronous code instead of completion handlers.

### ✅ Good Example
```swift
class UserService {
    func fetchUser(id: String) async throws -> User {
        let data = try await networkClient.data(from: endpoint(for: id))
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func updateProfile() async {
        do {
            let user = try await fetchUser(id: currentUserID)
            let image = try await downloadImage(from: user.avatarURL)
            await MainActor.run {
                profileImageView.image = image
                nameLabel.text = user.name
            }
        } catch {
            print("Failed to update profile: \(error)")
        }
    }
}
```

### ❌ Bad Example
```swift
class UserService {
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        networkClient.request(endpoint: endpoint(for: id)) { result in
            switch result {
            case .success(let data):
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Nested completion handlers (callback hell)
    func updateProfile() {
        fetchUser(id: currentUserID) { [weak self] userResult in
            switch userResult {
            case .success(let user):
                self?.downloadImage(from: user.avatarURL) { imageResult in
                    switch imageResult {
                    case .success(let image):
                        DispatchQueue.main.async {
                            self?.profileImageView.image = image
                            self?.nameLabel.text = user.name
                        }
                    case .failure(let error):
                        print("Failed: \(error)")
                    }
                }
            case .failure(let error):
                print("Failed: \(error)")
            }
        }
    }
}
```

## 8. Use Computed Properties Instead of Methods for Simple Getters

When a property can be computed without side effects and doesn't require parameters, use a computed property instead of a method.

### ✅ Good Example
```swift
struct Rectangle {
    let width: Double
    let height: Double
    
    var area: Double {
        width * height
    }
    
    var perimeter: Double {
        2 * (width + height)
    }
    
    var isSquare: Bool {
        width == height
    }
}

extension User {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var isAdult: Bool {
        age >= 18
    }
}
```

### ❌ Bad Example
```swift
struct Rectangle {
    let width: Double
    let height: Double
    
    func getArea() -> Double {
        return width * height
    }
    
    func getPerimeter() -> Double {
        return 2 * (width + height)
    }
    
    func checkIfSquare() -> Bool {
        return width == height
    }
}

extension User {
    func getFullName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    func checkIfAdult() -> Bool {
        return age >= 18
    }
}
```

## 9. Use Enums for Finite State and Associated Values

Leverage Swift's powerful enums for representing state, configuration options, and values with associated data.

### ✅ Good Example
```swift
enum NetworkState {
    case idle
    case loading
    case success(Data)
    case failure(Error)
}

enum UserAction {
    case login(email: String, password: String)
    case logout
    case updateProfile(name: String?, avatar: UIImage?)
    case deleteAccount(reason: String)
}

class ViewModel {
    var state: NetworkState = .idle {
        didSet {
            updateUI(for: state)
        }
    }
    
    func updateUI(for state: NetworkState) {
        switch state {
        case .idle:
            hideLoader()
        case .loading:
            showLoader()
        case .success(let data):
            hideLoader()
            displayData(data)
        case .failure(let error):
            hideLoader()
            showError(error)
        }
    }
}
```

### ❌ Bad Example
```swift
class ViewModel {
    var isLoading = false
    var data: Data?
    var error: Error?
    var hasError = false
    
    func updateUI() {
        if isLoading {
            showLoader()
        } else {
            hideLoader()
            
            if hasError, let error = error {
                showError(error)
            } else if let data = data {
                displayData(data)
            }
        }
    }
}

// Using strings or integers for actions
func handleAction(_ action: String, parameters: [String: Any]?) {
    switch action {
    case "login":
        // Extract parameters manually
    case "logout":
        // Handle logout
    default:
        break
    }
}
```

## 10. Follow Swift API Design Guidelines for Naming

Use clear, expressive names that read like English phrases. Methods and functions should be verb phrases, while properties and types should be noun phrases.

### ✅ Good Example
```swift
// Methods read like English phrases
view.addSubview(button)
array.append(element)
set.contains(element)
users.removeAll()

// Clear parameter labels
func move(from startPoint: CGPoint, to endPoint: CGPoint)
func resize(to size: CGSize, animated: Bool)
func configure(with user: User)

// Boolean properties read as assertions
var isEnabled: Bool
var hasChanges: Bool
var canEdit: Bool

// Factory methods are clear
class Theme {
    static func makeDefaultTheme() -> Theme
    static func makeTheme(withPrimaryColor color: UIColor) -> Theme
}

// Protocol names describe capabilities or roles
protocol Drawable {
    func draw()
}

protocol DataSource {
    func numberOfItems() -> Int
}
```

### ❌ Bad Example
```swift
// Unclear or redundant naming
view.addSubviewToView(button)  // Redundant
array.appendElement(element)   // Redundant
set.hasElement(element)        // Should be 'contains'
users.empty()                   // Should be 'removeAll'

// Poor parameter labels
func move(_ p1: CGPoint, _ p2: CGPoint)  // Unclear
func resize(s: CGSize, a: Bool)          // Cryptic
func configure(u: User)                  // Unnecessary abbreviation

// Boolean properties that don't read as assertions
var enabled: Bool      // Should be 'isEnabled'
var changes: Bool      // Should be 'hasChanges'
var edit: Bool         // Should be 'canEdit'

// Unclear factory methods
class Theme {
    static func theme() -> Theme              // Too vague
    static func getTheme(_ color: UIColor)    // 'get' is unnecessary
}

// Protocol names that don't describe capability
protocol DrawProtocol {    // 'Protocol' suffix is redundant
    func draw()
}
```

## Summary

These 10 rules represent the core of modern iOS Swift development practices. Following them will result in code that is:
- More maintainable and readable
- Less prone to common bugs (like retain cycles)
- More "Swifty" - taking advantage of the language's features
- Easier for other iOS developers to understand and work with

Remember that consistency within a codebase is often more important than following any particular style guide perfectly. When joining an existing project, adapt to its conventions while gradually introducing improvements.