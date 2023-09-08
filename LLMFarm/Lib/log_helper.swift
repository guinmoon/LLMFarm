//
//  log_helper.swift
//  LLMFarm
//
//  Created by guinmoon on 02.09.2023.
//

import Foundation
//


class OutputListener {
    /// consumes the messages on STDOUT
    let inputPipe = Pipe()

    /// outputs messages back to STDOUT
    let outputPipe = Pipe()

    /// Buffers strings written to stdout
    var contents = ""
    init(){
        let outPipe = Pipe()
        var outString = "Initial"
        let sema = DispatchSemaphore(value: 0)
        outPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty  { // end-of-file condition
                fileHandle.readabilityHandler = nil
                sema.signal()
            } else {
                outString += String(data: data,  encoding: .utf8)!
            }
        }
        print("Starting")

        // Redirect
        setvbuf(stdout, nil, _IONBF, 0)
        let savedStdout = dup(STDERR_FILENO)
        dup2(outPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    }
//    init() {
//        // Set up a read handler which fires when data is written to our inputPipe
//        inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
//            guard let strongSelf = self else { return }
//
//            let data = fileHandle.availableData
//            if let string = String(data: data, encoding: String.Encoding.utf8) {
//                strongSelf.contents += string
//            }
//
//            // Write input back to stdout
//            strongSelf.outputPipe.fileHandleForWriting.write(data)
//        }
//    }
//
//    func openConsolePipe() {
//        // Copy STDOUT file descriptor to outputPipe for writing strings back to STDOUT
//        dup2(stdoutFileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)
//
//        // Intercept STDOUT with inputPipe
//        dup2(inputPipe.fileHandleForWriting.fileDescriptor, stdoutFileDescriptor)
//    }
//
//    func closeConsolePipe() {
//        // Restore stdout
//        freopen("/dev/stdout", "a", stdout)
//
//        [inputPipe.fileHandleForReading, outputPipe.fileHandleForWriting].forEach { file in
//            file.closeFile()
//        }
//    }
}

//func openConsolePipe() {
//    //open a new Pipe to consume the messages on STDOUT and STDERR
//    inputPipe = Pipe()
//
//    //open another Pipe to output messages back to STDOUT
//    outputPipe = Pipe()
//
//    guard let inputPipe = inputPipe, let outputPipe = outputPipe else {
//        return
//    }
//
//    let pipeReadHandle = inputPipe.fileHandleForReading
//
//    //from documentation
//    //dup2() makes newfd (new file descriptor) be the copy of oldfd (old file descriptor), closing newfd first if necessary.
//
//    //here we are copying the STDOUT file descriptor into our output pipe's file descriptor
//    //this is so we can write the strings back to STDOUT, so it can show up on the xcode console
//    dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)
//
//    //In this case, the newFileDescriptor is the pipe's file descriptor and the old file descriptor is STDOUT_FILENO and STDERR_FILENO
//
//    dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
//    dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
//
//    //listen in to the readHandle notification
//    NotificationCenter.default.addObserver(self, selector: #selector(self.handlePipeNotification), name: FileHandle.readCompletionNotification, object: pipeReadHandle)
//
//    //state that you want to be notified of any data coming across the pipe
//    pipeReadHandle.readInBackgroundAndNotify()
//}
//
//func handlePipeNotification(notification: Notification) {
//    //note you have to continuously call this when you get a message
//    //see this from documentation:
//    //Note that this method does not cause a continuous stream of notifications to be sent. If you wish to keep getting notified, you’ll also need to call readInBackgroundAndNotify() in your observer method.
//    inputPipe?.fileHandleForReading.readInBackgroundAndNotify()
//
//    if let data = notification.userInfo[NSFileHandleNotificationDataItem] as? Data,
//       let str = String(data: data, encoding: String.Encoding.ascii) {
//
//        //write the data back into the output pipe. the output pipe's write file descriptor points to STDOUT. this allows the logs to show up on the xcode console
//        outputPipe?.fileHandleForWriting.write(data)
//
//        // `str` here is the log/contents of the print statement
//        //if you would like to route your print statements to the UI: make
//        //sure to subscribe to this notification in your VC and update the UITextView.
//        //Or if you wanted to send your print statements to the server, then
//        //you could do this in your notification handler in the app delegate.
//    }
//}
