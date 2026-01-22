import UIKit
import A

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "CheckAppSMP"
        
        // Create button for demonstration
        let button = UIButton(type: .system)
        button.setTitle("Call AThing.demo()", for: .normal)
        button.addTarget(self, action: #selector(demoButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func demoButtonTapped() {
        let thing = AThing()
        thing.demo()
        
        let alert = UIAlertController(
            title: "Success",
            message: "Method demo() called via SPM. Check console.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
