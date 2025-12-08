import UIKit

class SlidingTabBarDelegate: NSObject, UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let fromIndex = tabBarController.viewControllers?.firstIndex(of: fromVC) ?? 0
        let toIndex = tabBarController.viewControllers?.firstIndex(of: toVC) ?? 0
        return SlidingTransitionAnimator(direction: toIndex > fromIndex ? .left : .right)
    }
}

class SlidingTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum Direction {
        case left, right
    }
    
    private let direction: Direction
    private let duration: TimeInterval = 0.3
    
    init(direction: Direction) {
        self.direction = direction
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let width = containerView.frame.width
        
        let offset = direction == .left ? width : -width
        
        toView.frame = containerView.bounds.offsetBy(dx: offset, dy: 0)
        containerView.addSubview(toView)
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            fromView.frame = containerView.bounds.offsetBy(dx: -offset, dy: 0)
            toView.frame = containerView.bounds
        }) { completed in
            fromView.frame = containerView.bounds // Reset fromView frame
            transitionContext.completeTransition(completed)
        }
    }
}
