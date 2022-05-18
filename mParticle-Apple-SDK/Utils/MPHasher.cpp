#include "MPHasher.h"
#include <algorithm>

namespace mParticle {
    int Hasher::hashFromString(const string &stringToHash) {
        if (stringToHash.empty()) {
            return 0;
        }

        string lowerCaseStringToHash = stringToHash;
        transform(lowerCaseStringToHash.begin(), lowerCaseStringToHash.end(), lowerCaseStringToHash.begin(), ::tolower);
        
        unsigned int hash = 0;
        for (auto &character : lowerCaseStringToHash) {
            hash = ((hash << 5) - hash) + character;
        }
        
        return hash;
    }

    string Hasher::hashString(string stringToHash) {
        if (stringToHash.empty()) {
            return "";
        }
        
        auto hash = Hasher::hashFromString(stringToHash);
        
        auto hashString = to_string(hash);
        return hashString;
    }
    
    vector<string> Hasher::hashedEventTypes(const vector<int> &eventTypes) {
        vector<string> hashedTypes;

        if (eventTypes.empty()) {
            return hashedTypes;
        }
        
        for (auto &eventType : eventTypes) {
            auto eventTypeString = to_string(eventType);
            auto hashedEventType = Hasher::hashString(eventTypeString);
            hashedTypes.push_back(hashedEventType);
        }
        
        return hashedTypes;
    }
    
    vector<string> Hasher::hashedAllEventTypes() {
        vector<int> eventTypes(22);
        
        int i = 0;
        for_each(eventTypes.begin(), eventTypes.end(), [&i](int &eventType) {eventType = i++;});
        
        vector<string> hashes = Hasher::hashedEventTypes(eventTypes);
        return hashes;
    }
    
    string Hasher::hashEvent(string eventName, string eventType) {
        eventName.append(eventType);
        return Hasher::hashString(eventName);
    }

    int64_t Hasher::hashFNV1a(const char *bytes, int length) {
        // FNV-1a hashing
        uint64_t rampHash = 0xcbf29ce484222325;
        
        int i = 0;
        while (i < length) {
            rampHash = (rampHash ^ bytes[i]) * 0x100000001B3;
            i += 1;
        }
        
        return rampHash;
    }
}
