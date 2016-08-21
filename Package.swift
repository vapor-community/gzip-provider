import PackageDescription

let package = Package(
    name: "gzip-vapor",
    dependencies: [
    	.Package(url: "https://github.com/Zewo/gzip.git", majorVersion: 0, minor: 6),
    	.Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 16)
    ]
)
