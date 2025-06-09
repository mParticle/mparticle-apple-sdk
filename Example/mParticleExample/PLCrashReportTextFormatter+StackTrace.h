//@import CrashReporter;
//
//NS_ASSUME_NONNULL_BEGIN
//
//
//@interface PLCrashReportTextFormatter (Private)
//
//+ (NSString *) formatStackFrame:(PLCrashReportStackFrameInfo *)frameInfo
//                     frameIndex:(NSUInteger)frameIndex
//                         report:(PLCrashReport *)report
//                           lp64:(BOOL)lp64;
//
//@end
//
//@interface PLCrashReportTextFormatter (StackTrace)
//
//+ (NSString *)stringValueStackTraceForCrashReport:(PLCrashReport *)report;
//+ (boolean_t)isLp64Report:(PLCrashReport *)report;
//
//@end
//
//@implementation PLCrashReportTextFormatter (StackTrace)
//
//+ (NSString *)stringValueStackTraceForCrashReport:(PLCrashReport *)report {
//    boolean_t lp64 = [PLCrashReportTextFormatter isLp64Report:report];
//    NSMutableString *stackTrace = [@"" mutableCopy];
//    if (report.exceptionInfo != nil && report.exceptionInfo.stackFrames != nil && [report.exceptionInfo.stackFrames count] > 0) {
//        PLCrashReportExceptionInfo *exception = report.exceptionInfo;
//        for (NSUInteger frame_idx = 0; frame_idx < [exception.stackFrames count]; frame_idx++) {
//            PLCrashReportStackFrameInfo *frameInfo = [exception.stackFrames objectAtIndex: frame_idx];
//            [stackTrace appendString: [PLCrashReportTextFormatter formatStackFrame: frameInfo frameIndex: frame_idx report: report lp64: lp64]];
//        }
//        [stackTrace appendString: @"\n"];
//    }
//    return stackTrace;
//}
//
//+ (boolean_t)isLp64Report:(PLCrashReport *)report {
//    boolean_t lp64 = true; // quiesce GCC uninitialized value warning
//    
//    /* Map to Apple-style code type, and mark whether architecture is LP64 (64-bit) */
//    NSString *codeType = nil;
//    
//    /* Attempt to derive the code type from the binary images */
//    for (PLCrashReportBinaryImageInfo *image in report.images) {
//        /* Skip images with no specified type */
//        if (image.codeType == nil)
//            continue;
//
//        /* Skip unknown encodings */
//        if (image.codeType.typeEncoding != PLCrashReportProcessorTypeEncodingMach)
//            continue;
//        
//        switch (image.codeType.type) {
//            case CPU_TYPE_ARM:
//                codeType = @"ARM";
//                lp64 = false;
//                break;
//                
//            case CPU_TYPE_ARM64:
//                codeType = @"ARM-64";
//                lp64 = true;
//                break;
//
//            case CPU_TYPE_X86:
//                codeType = @"X86";
//                lp64 = false;
//                break;
//
//            case CPU_TYPE_X86_64:
//                codeType = @"X86-64";
//                lp64 = true;
//                break;
//
//            case CPU_TYPE_POWERPC:
//                codeType = @"PPC";
//                lp64 = false;
//                break;
//                
//            default:
//                // Do nothing, handled below.
//                break;
//        }
//
//        /* Stop immediately if code type was discovered */
//        if (codeType != nil)
//            break;
//    }
//
//    /* If we were unable to determine the code type, fall back on the processor info's value. */
//    if (codeType == nil && report.systemInfo.processorInfo.typeEncoding == PLCrashReportProcessorTypeEncodingMach) {
//        switch (report.systemInfo.processorInfo.type) {
//            case CPU_TYPE_ARM:
//                codeType = @"ARM";
//                lp64 = false;
//                break;
//
//            case CPU_TYPE_ARM64:
//                codeType = @"ARM-64";
//                lp64 = true;
//                break;
//
//            case CPU_TYPE_X86:
//                codeType = @"X86";
//                lp64 = false;
//                break;
//
//            case CPU_TYPE_X86_64:
//                codeType = @"X86-64";
//                lp64 = true;
//                break;
//
//            case CPU_TYPE_POWERPC:
//                codeType = @"PPC";
//                lp64 = false;
//                break;
//
//            default:
//                codeType = [NSString stringWithFormat: @"Unknown (%llu)", report.systemInfo.processorInfo.type];
//                lp64 = true;
//                break;
//        }
//    }
//    
//    /* If we still haven't determined the code type, we're totally clueless. */
//    if (codeType == nil) {
//        codeType = @"Unknown";
//        lp64 = true;
//    }
//    
//    return lp64;
//}
//
//@end
//
//NS_ASSUME_NONNULL_END
