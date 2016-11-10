//
//  AppDelegate.swift
//  trax
//
//  Created by Cristina Rodriguez Fernandez on 15/8/16.
//  Copyright © 2016 CrisRodFe. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate
{
    // MARK: Public Model
    var gpxURL: URL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                //GPX es una clase facilitada por el profesor.
                GPX.parse(url) { gpx in //.parse es asíncrono.
                    if gpx != nil {
                        self.addWaypoints(gpx!.waypoints)
                    }
                }
            }
        }
    }
    
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        gpxURL = URL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }
    
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .satellite
            mapView.delegate = self
        }
    }
    
    
    // MARK: Private Implementation
    fileprivate func clearWaypoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    fileprivate func addWaypoints(_ waypoints: [GPX.Waypoint]) {
        mapView?.addAnnotations(waypoints)
        mapView?.showAnnotations(waypoints, animated: true)
    }
    
    fileprivate func selectWaypoint(_ waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    
    // MARK: MKMapViewDelegate
    //Configuración de nuestro view donde está desplegado el mapa
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.isDraggable = annotation is EditableWaypoint
    
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        
        //Si tenemos una foto en la chincheta se mostrará. si no, no aparecerá nada, no aparece un cuadrado vació porque pusimos
        // que el CalloutAccessoryView era nil. Si es una chincheta que podemos editar, aparece el botton de la i circulo azul.
        if let waypoint = annotation as? GPX.Waypoint
        {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
        
        return view
    }
    
    //Si hay una thumbnail y se ha pulsado la chincheta buscara esa imagen y la cargará
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = try? Data(contentsOf: url as URL), // blocks main queue
            let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, for: UIControlState())
        }
    }
    
    //Añade otra funcionalidad. Cuando se pulse en el thumbnail(leftcallACcesoryView) hará segue a un imageviewcontroller con la foto en un scrollview.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegue(withIdentifier: Constants.ShowImageSegue, sender: view)
        } else if control == view.rightCalloutAccessoryView  {
            mapView.deselectAnnotation(view.annotation, animated: true)
            performSegue(withIdentifier: Constants.EditUserWaypoint, sender: view)
        }
    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        } else if segue.identifier == Constants.EditUserWaypoint
        {
            if let editableWaypoint = waypoint as? EditableWaypoint,
               let ewvc = destination as? EditWaypointViewController
                {
                    if let ppc = ewvc.popoverPresentationController
                    {
                        ppc.sourceRect = annotationView!.frame
                        ppc.delegate = self
                    }
                ewvc.waypointToEdit = editableWaypoint
            }
        }
    }
    
    
    // Long press gesture adds a waypoint
    @IBAction func addWaypoint(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began
        {
            let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
        }
    }
    
    
    // Unwind target (selects just-edited waypoint)
    @IBAction func updatedUserWaypoint(_ segue: UIStoryboardSegue) {
        selectWaypoint((segue.source.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    // when popover is dismissed, selected the just-edited waypoint
    // see also unwind target above (does the same thing for adapted UI)
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        selectWaypoint((popoverPresentationController.presentedViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    
    // if we're horizontally compact
    // then adapt by going to .OverFullScreen
    // .OverFullScreen fills the whole screen, but lets underlying MVC show through
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .compact ? .overFullScreen : .none
    }
    
    
    // when adapting to full screen
    // wrap the MVC in a navigation controller
    // and install a blurring visual effect behind all the navigation controller draws
    // autoresizingMask is "old style" constraints
    func presentationController(
        _ controller: UIPresentationController,
        viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle
    ) -> UIViewController? {
        if style == .fullScreen || style == .overFullScreen {
            let navcon = UINavigationController(rootViewController: controller.presentedViewController)
            let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            visualEffectView.frame = navcon.view.bounds
            visualEffectView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            navcon.view.insertSubview(visualEffectView, at: 0)
            return navcon
        } else {
            return nil
        }
    }
    
    
    // MARK: Constants
    fileprivate struct Constants
    {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59) // sad face
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }
}

extension UIViewController { //Usado en el navigation segue
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}


