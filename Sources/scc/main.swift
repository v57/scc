import Foundation

func shell(launchPath: String, arguments: [String]) -> String? {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)
    
    return output
}

var dir = shell(launchPath: "/bin/pwd", arguments: [])!
dir = String(dir[..<dir.index(before: dir.endIndex)]) + "/"
let args = CommandLine.arguments
var fileExtension = ".swift"
if args.count > 1 {
    fileExtension = "." + args[1]
}

let contents = try! FileManager.default.subpathsOfDirectory(atPath: dir)
    .filter { $0.hasSuffix(fileExtension) }
    .map { URL(fileURLWithPath: dir + $0) }

if contents.isEmpty {
    print("Swift files not found")
    exit(1)
}

print("Files: \(contents.count)")

var failed = 0
var array = [Int]()
array.reserveCapacity(10000)

let lock = NSLock()
let queue = OperationQueue()
contents.forEach { url in
    queue.addOperation {
        do {
            let lines = try String(contentsOf: url)
                .split(separator: "\n")
            lock.lock()
            array.append(contentsOf: lines.map { $0.count })
            lock.unlock()
        } catch {
            lock.lock()
            failed += 1
            lock.unlock()
        }
    }
}
queue.waitUntilAllOperationsAreFinished()
var total = 0 // total characters
array.forEach { line in
    total += line
}
if total == 0 {
    print("All swift files are empty")
    exit(1)
}

print("Lines: \(array.count)")

for lineWidth in [100,90,80,70,60,50,40,30,20] {
    var below = 0
    var above = 0
    array.forEach { line in
        if line > lineWidth {
            above += 1
        } else {
            below += 1
        }
    }
    let percentage = Int((Double(above) / Double(above + below)) * 100)
    print("Above \(lineWidth) characters: \(percentage)% (\(above))")
}

print("Average line size: \(total / array.count)")
