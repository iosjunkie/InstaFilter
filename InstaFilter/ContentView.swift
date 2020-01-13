//
//  ContentView.swift
//  InstaFilter
//
//  Created by Jules Lee on 1/12/20.
//  Copyright © 2020 Jules Lee. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    
    @State private var showingImagePicker = false
    @State private var showingFilterSheet = false
    @State private var image: Image?
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    @State private var showingError = false
    @State private var errorMessage: String = ""
    
    @State private var filterIntensity = 0.5
    @State private var radius = 0.5
    @State private var scale = 0.5
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    
    @State private var showingIntensitySlider = true {
        didSet {
            if showingIntensitySlider {
                showingRadiusSlider = false
                showingScaleSlider = false
            }
        }
    }
    @State private var showingRadiusSlider = false {
        didSet {
            if showingRadiusSlider {
                showingIntensitySlider = false
                showingScaleSlider = false
            }
        }
    }
    @State private var showingScaleSlider = false {
        didSet {
            if showingScaleSlider {
                showingRadiusSlider = false
                showingIntensitySlider = false
            }
        }
    }

    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radius = Binding<Double>(
            get: {
                self.radius
            },
            set: {
                self.radius = $0
                self.applyProcessing()
            }
        )
        
        let scale = Binding<Double>(
            get: {
                self.scale
            },
            set: {
                self.scale = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)

                    // display the image
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    // select an image
                    self.showingImagePicker = true
                }

                VStack {
                    if self.showingIntensitySlider {
                        HStack {
                            Text("Intensity")
                            Slider(value: intensity)
                        }
                    }
                    
                    if self.showingRadiusSlider {
                        HStack {
                            Text("Radius")
                            Slider(value: radius)
                        }
                    }
                    
                    if self.showingScaleSlider {
                        HStack {
                            Text("Scale")
                            Slider(value: scale)
                        }
                    }
                }
                .padding()

                HStack {
                    Button(self.currentFilter.attributes[kCIAttributeFilterDisplayName] as! String) {
                        // change filter
                        self.showingFilterSheet = true
                    }

                    Spacer()

                    Button("Save") {
                        // save the picture
                        guard let processedImage = self.processedImage else {
                            self.errorMessage = "No Image selected"
                            self.showingError = true
                            return
                        }

                        let imageSaver = ImageSaver()
                        imageSaver.successHandler = {
                            print("Success!")
                        }

                        imageSaver.errorHandler = {
                            print("Oops: \($0.localizedDescription)")
                        }

                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
        .actionSheet(isPresented: $showingFilterSheet) {
            // action sheet here
            ActionSheet(title: Text("Select a filter"), buttons: [
                .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize()) },
                .default(Text("Edges")) { self.setFilter(CIFilter.edges()) },
                .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur()) },
                .default(Text("Pixellate")) { self.setFilter(CIFilter.pixellate()) },
                .default(Text("Sepia Tone")) { self.setFilter(CIFilter.sepiaTone()) },
                .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask()) },
                .default(Text("Vignette")) { self.setFilter(CIFilter.vignette()) },
                .cancel()
            ])
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text(self.errorMessage))
        }
        
        
        // An exercise to import and save the image back to photo library
//        VStack {
//            image?
//                .resizable()
//                .scaledToFit()
//
//            Button("Select Image") {
//               self.showingImagePicker = true
//            }
//        }
//        .onAppear(perform: loadImage)
//        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
//            ImagePicker(image: self.$inputImage)
//        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }

        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()

        // An exercise with CoreImage in adding a filter
//        guard let inputImage = UIImage(named: "Example") else { return }
//        let beginImage = CIImage(image: inputImage)
//
//        let context = CIContext()
//
//        guard let currentFilter = CIFilter(name: "CITwirlDistortion") else { return }
//        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
//        currentFilter.setValue(2000, forKey: kCIInputRadiusKey)
//        currentFilter.setValue(CIVector(x: inputImage.size.width / 2, y: inputImage.size.height / 2), forKey: kCIInputCenterKey)
//
//
////        let currentFilter = CIFilter.sepiaTone()
////        currentFilter.inputImage = beginImage
////        // Ranges from 0 to 1
////        currentFilter.intensity = 1
//
//        // get a CIImage from our filter or exit if that fails
//        guard let outputImage = currentFilter.outputImage else { return }
//
//        // attempt to get a CGImage from our CIImage
//        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
//            // convert that to a UIImage
//            let uiImage = UIImage(cgImage: cgimg)
//
//            // and convert that to a SwiftUI image
//            image = Image(uiImage: uiImage)
//        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }

        guard let outputImage = currentFilter.outputImage else { return }

        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        updateSliderss(for: filter)
        loadImage()
    }
    
    func updateSliderss(for filter: CIFilter) {
        let inputKeys = filter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { self.showingIntensitySlider = true }
        if inputKeys.contains(kCIInputRadiusKey) { self.showingRadiusSlider = true  }
        if inputKeys.contains(kCIInputScaleKey) { self.showingScaleSlider = true  }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
