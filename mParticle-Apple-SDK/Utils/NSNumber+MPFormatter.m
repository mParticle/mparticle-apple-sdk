#import "NSNumber+MPFormatter.h"

@implementation NSNumber(MPFormatter)

- (NSNumber *)formatWithNonScientificNotation {
    double minThreshold = 1.0E-5;
    double selfAbsoluteValue = fabs([self doubleValue]);
    NSNumber *formattedNumber;
    
    if (selfAbsoluteValue < minThreshold) {
        formattedNumber = @0;
    } else {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        numberFormatter.maximumFractionDigits = 2;
        NSString *stringRepresentation = [numberFormatter stringFromNumber:self];
        formattedNumber = [numberFormatter numberFromString:stringRepresentation];
    }
    
    return formattedNumber;
}

@end
