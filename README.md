# SPMLicenses

This tool reads your Package.resolved file and generates a json file including all licenses of your third party dependencies, given the dependency is hosted on GitHub. For more information see the blogpost:
https://dehlen.github.io/blog/swift,/dev/2020/12/24/generating-spm-licenses.html

Executing the tool is a single call on your command line:

```sh
$ swift run spm-licenses <path to .xcworkspace> <output.json> <optional GitHub client id> <optional GitHub client secret>
```

If you want to tinker with it or use the tool in one of your applications you can build SPMLicenses from source like so:

```sh
$ swift build -c release
$ cd .build/release
$ cp -f spm-licenses /usr/local/bin/spm-licenses
```

Or use [Mint](https://github.com/yonaskolb/Mint):

```sh
$ mint install dehlen/SPMLicenses
```

If you want to update the license file on every Xcode build you can add this simple script as a Run Script Build Phase. To set this up in Xcode, do the following:
1. Click on your project in the file list, choose your target under TARGETS, click the Build Phases tab
2. Add a New Run Script Phase by clicking the little plus icon in the top left and paste in the following script:

```sh
if which tribute >/dev/null; then
 spm-licenses <path to .xcworkspace> <output.json> <optional GitHub client id> <optional GitHub client secret>
else
  echo "warning: SPMLicenses not installed, download from https://github.com/dehlen/SPMLicenses"
fi
```

To wrap things up you can use this SwiftUI module to automatically render the generated licenses in your app:

```swift
import Foundation
import SwiftUI
import os

struct License: Codable, Identifiable {
    let licenseName: String
    let licenseText: String
    let packageName: String
    
    var id: String { packageName }
}

extension License {
    static let mock: License = .init(licenseName: "MIT", licenseText: "MIT license text", packageName: "Test Dependency")
}

final class LicensesViewModel: ObservableObject {
    @Published private(set) var licenses: [License] = []
    #warning("update subsystem string")
    private let logger = Logger(subsystem: "com.sample.app", category: String(describing: LicensesViewModel.self))

    init() {
        #warning("make sure licenses.json is added to the project")
        guard let url = Bundle.main.url(forResource: "licenses", withExtension: "json") else {
            logger.debug("Could not read licenses because file does not exist.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.licenses = try JSONDecoder().decode([License].self, from: data)
        } catch {
            logger.debug("Could not read licenses: \(error.localizedDescription, privacy: .public)")
        }
    }
}

struct LicensesView: View {
    @ObservedObject var viewModel: LicensesViewModel

    var body: some View {
        List(viewModel.licenses) { license in
            LicenseView(license: license)
        }.navigationBarTitle(Text("Licenses"), displayMode: .inline)
    }
}

struct LicensesView_Previews: PreviewProvider {
    static var previews: some View {
        LicensesView(viewModel: .init())
    }
}

struct LicenseView: View {
    let license: License
    var body: some View {
        NavigationLink(destination: LicenseDetailView(license: license)) {
            HStack {
                Text(license.packageName)
                    .font(.body)
                Spacer()
                Text(license.licenseName)
                    .font(.body)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView(license: .mock)
    }
}

struct LicenseDetailView: View {
    let license: License
    
    var body: some View {
        ScrollView {
            VStack {
                Text(license.licenseText)
                Spacer()
            }.padding()
        }.navigationBarTitle(Text(license.packageName), displayMode: .inline)
    }
}

struct LicenseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseDetailView(license: .mock)
    }
}
```
