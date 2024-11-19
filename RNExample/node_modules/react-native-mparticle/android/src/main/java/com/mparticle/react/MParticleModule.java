package com.mparticle.react;

import android.location.Location;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.mparticle.AttributionResult;
import com.mparticle.MParticle;
import com.mparticle.MPEvent;
import com.mparticle.Session;
import com.mparticle.UserAttributeListenerType;
import com.mparticle.commerce.CommerceEvent;
import com.mparticle.commerce.Impression;
import com.mparticle.commerce.Product;
import com.mparticle.commerce.TransactionAttributes;
import com.mparticle.commerce.Promotion;
import com.mparticle.consent.ConsentState;
import com.mparticle.consent.GDPRConsent;
import com.mparticle.consent.CCPAConsent;
import com.mparticle.identity.AliasRequest;
import com.mparticle.identity.IdentityApi;
import com.mparticle.identity.IdentityApiRequest;
import com.mparticle.identity.IdentityApiResult;
import com.mparticle.identity.MParticleUser;
import com.mparticle.identity.IdentityHttpResponse;
import com.mparticle.identity.TaskFailureListener;
import com.mparticle.identity.TaskSuccessListener;
import com.mparticle.internal.Logger;
import com.mparticle.UserAttributeListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Nullable;

public class MParticleModule extends ReactContextBaseJavaModule {


    private final static String LOG_TAG = "MParticleModule";

    ReactApplicationContext reactContext;

    public MParticleModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "MParticle";
    }

    @ReactMethod
    public void upload() {
        MParticle.getInstance().upload();
    }

    @ReactMethod
    public void setUploadInterval(int uploadInterval) {
        MParticle.getInstance().setUpdateInterval(uploadInterval);
    }

    @ReactMethod
    public void setLocation(double latitude, double longitude) {
        Location newLocation = new Location(""); 
        newLocation.setLatitude(latitude);
        newLocation.setLongitude(longitude);
        MParticle.getInstance().setLocation(newLocation);
        
    }

    @ReactMethod
    public void logEvent(final String name, int type, final ReadableMap attributesMap) {
        Map<String, String> attributes = ConvertStringMap(attributesMap);
        MParticle.EventType eventType = ConvertEventType(type);

        MPEvent event = new MPEvent.Builder(name, eventType)
                .customAttributes(attributes)
                .build();
        MParticle.getInstance().logEvent(event);
    }

    @ReactMethod
    public void logMPEvent(final ReadableMap attributesMap) {
        MPEvent event = ConvertMPEvent(attributesMap);
        MParticle.getInstance().logEvent(event);
    }

    @ReactMethod
    public void logCommerceEvent(final ReadableMap map) {
        if (map != null) {
            CommerceEvent commerceEvent = ConvertCommerceEvent(map);
            MParticle.getInstance().logEvent(commerceEvent);
        }
    }

    @ReactMethod
    public void logScreenEvent(final String event, final ReadableMap attributesMap, final boolean shouldUploadEvent) {
        Map<String, String> attributes = ConvertStringMap(attributesMap);
        MParticle.getInstance().logScreen(event, attributes, shouldUploadEvent);
    }

    @ReactMethod
    public void setUserAttribute(final String userId, final String userAttribute, final String value) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            selectedUser.setUserAttribute(userAttribute, value);
        }
    }

    @ReactMethod
    public void setUserAttributeArray(final String userId, final String key, final ReadableArray values) {
     if (values != null) {
        List<String> list = new ArrayList<String>();
        for (int i = 0; i < values.size(); ++i) {
            list.add(values.getString(i));
        }

         MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
         if (selectedUser != null) {
            selectedUser.setUserAttributeList(key, list);
        }
      }
    }

    @ReactMethod
    public void getUserAttributes(final String userId, final Callback completion) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            selectedUser.getUserAttributes(new UserAttributeListener() {
                @Override
                public void onUserAttributesReceived(Map<String, String> userAttributes, Map<String, List<String>> userAttributeLists, Long mpid) {
                    WritableMap resultMap = new WritableNativeMap();
                    for (Map.Entry<String, String> entry : userAttributes.entrySet()) {
                        resultMap.putString(entry.getKey(), entry.getValue());
                    }
                    for (Map.Entry<String, List<String>> entry : userAttributeLists.entrySet()) {
                        WritableArray resultArray = new WritableNativeArray();
                        List<String> valueList = entry.getValue();
                        for (String arrayVal : valueList) {
                            resultArray.pushString(arrayVal);
                        }
                        resultMap.putArray(entry.getKey(), resultArray);
                    }
                    completion.invoke(null, resultMap);
                }
            });
        } else {
            completion.invoke();
        }
    }

    @ReactMethod
    public void setUserTag(final String userId, final String tag) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            selectedUser.setUserTag(tag);
        }
    }

    @ReactMethod
    public void removeUserAttribute(final String userId, final String key) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            selectedUser.removeUserAttribute(key);
        }
    }

    @ReactMethod
    public void incrementUserAttribute(final String userId, final String key, final Integer value) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            selectedUser.incrementUserAttribute(key, value);
        }
    }
    @ReactMethod
    public void identify(final ReadableMap requestMap, final Callback completion) {
        IdentityApiRequest request = ConvertIdentityAPIRequest(requestMap);

        MParticle.getInstance().Identity().identify(request)
                .addFailureListener(new TaskFailureListener() {
                    @Override
                    public void onFailure(IdentityHttpResponse identityHttpResponse) {
                        completion.invoke(ConvertIdentityHttpResponse(identityHttpResponse), null);
                    }
                })
                .addSuccessListener(new TaskSuccessListener() {
                    @Override
                    public void onSuccess(IdentityApiResult identityApiResult) {
                        //Continue with login, and you can also access the new/updated user:
                        MParticleUser user = identityApiResult.getUser();
                        String userID = Long.toString(user.getId());
                        completion.invoke(null, userID);
                    }
                });
    }


    @ReactMethod
    public void login(final ReadableMap requestMap, final Callback completion) {
        IdentityApiRequest request = ConvertIdentityAPIRequest(requestMap);

        MParticle.getInstance().Identity().login(request)
            .addFailureListener(new TaskFailureListener() {
                @Override
                public void onFailure(IdentityHttpResponse identityHttpResponse) {
                    completion.invoke(ConvertIdentityHttpResponse(identityHttpResponse), null);
                }
            })
            .addSuccessListener(new TaskSuccessListener() {
                @Override
                public void onSuccess(IdentityApiResult identityApiResult) {
                    //Continue with login, and you can also access the new/updated user:
                    MParticleUser user = identityApiResult.getUser();
                    String userId = Long.toString(user.getId());
                    MParticleUser previousUser = identityApiResult.getPreviousUser();
                    String previousUserId = null;
                    if (previousUser != null) {
                        previousUserId = Long.toString(previousUser.getId());
                    }
                    completion.invoke(null, userId, previousUserId);
                }
            });
    }


    @ReactMethod
    public void logout(final ReadableMap requestMap, final Callback completion) {
        IdentityApiRequest request = ConvertIdentityAPIRequest(requestMap);

        MParticle.getInstance().Identity().logout(request)
            .addFailureListener(new TaskFailureListener() {
                    @Override
                    public void onFailure(IdentityHttpResponse identityHttpResponse) {
                        completion.invoke(ConvertIdentityHttpResponse(identityHttpResponse), null);
                    }
                })
            .addSuccessListener(new TaskSuccessListener() {
                @Override
                public void onSuccess(IdentityApiResult identityApiResult) {
                    //Continue with login, and you can also access the new/updated user:
                    MParticleUser user = identityApiResult.getUser();
                    String userID = Long.toString(user.getId());
                    completion.invoke(null, userID);
                }
            });
    }

    @ReactMethod
    public void modify(final ReadableMap requestMap, final Callback completion) {
        IdentityApiRequest request = ConvertIdentityAPIRequest(requestMap);

        MParticle.getInstance().Identity().modify(request)
            .addFailureListener(new TaskFailureListener() {
                @Override
                public void onFailure(IdentityHttpResponse identityHttpResponse) {
                    completion.invoke(ConvertIdentityHttpResponse(identityHttpResponse), null);
                }
            })
            .addSuccessListener(new TaskSuccessListener() {
                @Override
                public void onSuccess(IdentityApiResult identityApiResult) {
                    //Continue with login, and you can also access the new/updated user:
                    MParticleUser user = identityApiResult.getUser();
                    String userID = Long.toString(user.getId());
                    completion.invoke(null, userID);
                }
            });
    }

    @ReactMethod
    public void getCurrentUserWithCompletion(Callback completion) {
        MParticleUser currentUser = MParticle.getInstance().Identity().getCurrentUser();
        if (currentUser != null) {
            String userID = Long.toString(currentUser.getId());
            completion.invoke(null, userID);
        } else {
            completion.invoke(null, null);
        }

    }

    @ReactMethod
    public void aliasUsers(final ReadableMap readableMap, final Callback completion) {
        IdentityApi identityApi = MParticle.getInstance().Identity();
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        Long destinationMpid = null;
        Long sourceMpid = null;
        Long startTime = null;
        Long endTime = null;

        while (iterator.hasNextKey()) {
            try {
                switch (iterator.nextKey()) {
                    case "destinationMpid":
                        destinationMpid = Utils.getLong(readableMap, "destinationMpid", false);
                        break;
                    case "sourceMpid":
                        sourceMpid = Utils.getLong(readableMap, "sourceMpid", false);
                        break;
                    case "startTime":
                        startTime = Utils.getLong(readableMap, "startTime", true);
                        break;
                    case "endTime":
                        endTime = Utils.getLong(readableMap, "endTime", true);
                        break;
                }
            } catch (NumberFormatException ex) {
                Logger.error(ex.getMessage());
                completion.invoke(false, ex.getMessage());
                return;
            }
        }
        if (startTime == null && endTime == null) {
            MParticleUser sourceUser = null;
            MParticleUser destinationUser = null;
            if (sourceMpid != null) {
                sourceUser = identityApi.getUser(sourceMpid);
            }
            if (destinationMpid != null) {
                destinationUser = identityApi.getUser(destinationMpid);
            }
            if (sourceUser != null && destinationUser != null) {
                AliasRequest request = AliasRequest.builder(sourceUser, destinationUser).build();
                boolean success = MParticle.getInstance().Identity().aliasUsers(request);
                completion.invoke(success);
            } else {
                completion.invoke(false, "MParticleUser could not be found for provided sourceMpid and destinationMpid");
            }
        } else {
            AliasRequest request = AliasRequest.builder()
                    .destinationMpid(destinationMpid)
                    .sourceMpid(sourceMpid)
                    .startTime(startTime)
                    .endTime(endTime)
                    .build();
            boolean success = identityApi.aliasUsers(request);
            completion.invoke(success);
        }
    }

    @ReactMethod
    public void getSession(Callback completion) {
        Session session = MParticle.getInstance().getCurrentSession();
        if (session != null) {
            String sessionId = session.getSessionUUID();
            completion.invoke(sessionId);
        } else {
            completion.invoke();
        }
    }

    @ReactMethod
    public void getUserIdentities(final String userId, Callback completion) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(parseMpid(userId));
        if (selectedUser != null) {
            completion.invoke(null, ConvertToUserIdentities(selectedUser.getUserIdentities()));
        } else {
            completion.invoke();
        }
    }

    @ReactMethod
    public void getFirstSeen(final String userId, Callback completion) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(Utils.parseMpid(userId));
        if (selectedUser != null) {
            completion.invoke(String.valueOf(selectedUser.getFirstSeenTime()));
        } else {
            completion.invoke();
        }
    }

    @ReactMethod
    public void getLastSeen(final String userId, Callback completion) {
        MParticleUser selectedUser = MParticle.getInstance().Identity().getUser(Utils.parseMpid(userId));
        if (selectedUser != null) {
            completion.invoke(String.valueOf(selectedUser.getLastSeenTime()));
        } else {
            completion.invoke();
        }
    }

    @ReactMethod
    public void getAttributions(Callback completion) {
        Map<Integer, AttributionResult> attributionResultMap = MParticle.getInstance().getAttributionResults();
        WritableMap map = Arguments.createMap();
        if (attributionResultMap != null) {
            for (Map.Entry<Integer, AttributionResult> entry : attributionResultMap.entrySet()) {
                WritableMap attributeMap = Arguments.createMap();
                AttributionResult attribution = entry.getValue();
                if (attribution != null) {
                    attributeMap.putInt("kitId", attribution.getServiceProviderId());
                    if (attribution.getLink() != null) {
                        attributeMap.putString("link", attribution.getLink());
                    }
                    if (attribution.getParameters() != null) {
                        attributeMap.putString("linkParameters", attribution.getParameters().toString());
                    }
                }
                map.putMap(String.valueOf(entry.getKey()), attributeMap);
            }
        }
        completion.invoke(map);
    }

    @ReactMethod
    public void setOptOut(Boolean optOut) {
        MParticle.getInstance().setOptOut(optOut);
    }

    @ReactMethod
    public void getOptOut(Callback completion) {
        boolean optedOut = MParticle.getInstance().getOptOut();
        completion.invoke(optedOut);
    }

    @ReactMethod
    public void isKitActive(Integer kitId, Callback completion) {
        boolean isActive = MParticle.getInstance().isKitActive(kitId);
        completion.invoke(isActive);
    }

    @ReactMethod
    public void logPushRegistration(String instanceId, String senderId) {
        if (!isEmpty(instanceId) && !isEmpty(senderId)) {
            MParticle.getInstance().logPushRegistration(instanceId, senderId);
        }
    }

    @ReactMethod
    public void addGDPRConsentState(final ReadableMap map, String purpose) {
        MParticleUser currentUser = MParticle.getInstance().Identity().getCurrentUser();
        if (currentUser != null) {


            GDPRConsent consent = ConvertToGDPRConsent(map);
            if (consent != null) {
                ConsentState consentState = ConsentState.withConsentState(currentUser.getConsentState())
                        .addGDPRConsentState(purpose, consent)
                        .build();
                currentUser.setConsentState(consentState);
                Logger.info("GDPRConsentState added, \n\t\"purpose\": " + purpose + "\n" + consentState.toString());
            } else {
                Logger.warning("GDPRConsentState was not able to be deserialized, will not be added");
            }
        }
    }

    @ReactMethod
    public void removeGDPRConsentStateWithPurpose(String purpose) {
        MParticleUser currentUser = MParticle.getInstance().Identity().getCurrentUser();
        if (currentUser != null) {
            ConsentState consentState = ConsentState.withConsentState(currentUser.getConsentState())
                    .removeGDPRConsentState(purpose)
                    .build();
            currentUser.setConsentState(consentState);
        }
    }

        @ReactMethod
    public void setCCPAConsentState(final ReadableMap map) {
        MParticleUser currentUser = MParticle.getInstance().Identity().getCurrentUser();
        if (currentUser != null) {


            CCPAConsent consent = ConvertToCCPAConsent(map);
            if (consent != null) {
                ConsentState consentState = ConsentState.withConsentState(currentUser.getConsentState())
                        .setCCPAConsentState(consent)
                        .build();
                currentUser.setConsentState(consentState);
                Logger.info("CCPAConsentState added, \n" + consentState.toString());
            } else {
                Logger.warning("CCPAConsentState was not able to be deserialized, will not be added");
            }
        }
    }

    @ReactMethod
    public void removeCCPAConsentState() {
        MParticleUser currentUser = MParticle.getInstance().Identity().getCurrentUser();
        if (currentUser != null) {
            ConsentState consentState = ConsentState.withConsentState(currentUser.getConsentState())
                    .removeCCPAConsentState()
                    .build();
            currentUser.setConsentState(consentState);
        }
    }

    protected WritableMap getWritableMap() {
        return new WritableNativeMap();
    }

    private static IdentityApiRequest ConvertIdentityAPIRequest(ReadableMap map) {
        IdentityApiRequest.Builder identityRequest = IdentityApiRequest.withEmptyUser();
        Map<MParticle.IdentityType, String> userIdentities = ConvertUserIdentities(map);
        identityRequest.userIdentities(userIdentities);

        return identityRequest.build();
    }

    private static MPEvent ConvertMPEvent(ReadableMap map) {
        if ((map.hasKey("name")) && (map.hasKey("type"))) {
            String name = map.getString("name");
            Integer type = map.getInt("type");

            MPEvent.Builder builder = new MPEvent.Builder(name, ConvertEventType(type));

            if (map.hasKey("category")) {
                builder.category(map.getString("category"));
            }

            if (map.hasKey("duration")) {
                builder.duration(map.getDouble("duration"));
            }

            if (map.hasKey("info")) {
                ReadableMap customInfoMap = map.getMap("info");
                Map<String, String> customInfo = ConvertStringMap(customInfoMap);
                builder.customAttributes(customInfo);
            }

            if (map.hasKey("customFlags")) {
                ReadableMap customFlagsMap = map.getMap("customFlags");
                Map<String, String> customFlags = ConvertStringMap(customFlagsMap);
                for (Map.Entry<String, String> entry : customFlags.entrySet())
                {
                    builder.addCustomFlag(entry.getKey(), entry.getValue());
                }
            }

            if (map.hasKey("shouldUploadEvent")) {
                builder.shouldUploadEvent(map.getBoolean("shouldUploadEvent"));
            }

            return  builder.build();
        }

        return null;
    }

    private static ReadableMap ConvertIdentityHttpResponse(IdentityHttpResponse response) {
        WritableMap map = Arguments.createMap();
        map.putInt("httpCode", response.getHttpCode());
        if (response.getMpId() != 0) {
            map.putString("mpid", String.valueOf(response.getMpId()));
        }
        StringBuilder stringBuilder = new StringBuilder();
        if (response.getErrors() != null) {
            for (IdentityHttpResponse.Error error: response.getErrors()) {
                if (error != null) {
                    stringBuilder.append("Code: " + error.code + "\n");
                    stringBuilder.append("Message: " + error.message + "\n");
                }
            }
        }
        map.putString("errors", stringBuilder.toString());
        return map;
    }

    private static CommerceEvent ConvertCommerceEvent(ReadableMap map) {
        Boolean isProductAction = map.hasKey("productActionType");
        Boolean isPromotion = map.hasKey("promotionActionType");
        Boolean isImpression = map.hasKey("impressions");

        if (!isProductAction && !isPromotion && !isImpression) {
            Log.e(LOG_TAG, "Invalid commerce event:" + map.toString());
            return null;
        }

        CommerceEvent.Builder builder = null;

        if (isProductAction) {
            int productActionInt = map.getInt("productActionType");
            String productAction = ConvertProductActionType(productActionInt);
            ReadableArray productsArray = map.getArray("products");
            ReadableMap productMap = productsArray.getMap(0);
            Product product = ConvertProduct(productMap);
            ReadableMap transactionAttributesMap = map.getMap("transactionAttributes");
            TransactionAttributes transactionAttributes = ConvertTransactionAttributes(transactionAttributesMap);
            builder = new CommerceEvent.Builder(productAction, product).transactionAttributes(transactionAttributes);

            for (int i = 1; i < productsArray.size(); ++i) {
                productMap = productsArray.getMap(i);
                product = ConvertProduct(productMap);
                builder.addProduct(product);
            }
        }
        else if (isPromotion) {
            int promotionActionTypeInt = map.getInt("promotionActionType");
            String promotionAction = ConvertPromotionActionType(promotionActionTypeInt);
            ReadableArray promotionsReadableArray = map.getArray("promotions");
            ReadableMap promotionMap = promotionsReadableArray.getMap(0);
            Promotion promotion = ConvertPromotion(promotionMap);
            builder = new CommerceEvent.Builder(promotionAction, promotion);

            for (int i = 1; i < promotionsReadableArray.size(); ++i) {
                promotionMap = promotionsReadableArray.getMap(i);
                promotion = ConvertPromotion(promotionMap);
                builder.addPromotion(promotion);
            }
        }
        else {
            ReadableArray impressionsArray = map.getArray("impressions");
            ReadableMap impressionMap = impressionsArray.getMap(0);
            Impression impression = ConvertImpression(impressionMap);
            builder = new CommerceEvent.Builder(impression);

            for (int i = 1; i < impressionsArray.size(); ++i) {
                impressionMap = impressionsArray.getMap(i);
                impression = ConvertImpression(impressionMap);
                builder.addImpression(impression);
            }
        }

        if (map.hasKey("shouldUploadEvent")) {
            builder.shouldUploadEvent(map.getBoolean("shouldUploadEvent"));
        }
        if (map.hasKey("customAttributes")) {
            builder.customAttributes(ConvertStringMap(map.getMap("customAttributes")));
        }
        if (map.hasKey("currency")) {
            builder.currency(map.getString("currency"));
        }
        if (map.hasKey("checkoutStep")) {
            builder.checkoutStep(map.getInt("checkoutStep"));
        }
        if (map.hasKey("checkoutOptions")) {
            builder.checkoutOptions(map.getString("checkoutOptions"));
        }


        return builder.build();
    }

    private static Product ConvertProduct(ReadableMap map) {
        String name = map.getString("name");
        String sku = map.getString("sku");
        double unitPrice = map.getDouble("price");
        Product.Builder builder = new Product.Builder(name, sku, unitPrice);

        if (map.hasKey("brand")) {
            String brand = map.getString("brand");
            builder.brand(brand);
        }

        if (map.hasKey("category")) {
            String category = map.getString("category");
            builder.category(category);
        }

        if (map.hasKey("couponCode")) {
            String couponCode = map.getString("couponCode");
            builder.couponCode(couponCode);
        }

        if (map.hasKey("customAttributes")) {
            ReadableMap customAttributesMap = map.getMap("customAttributes");
            Map<String, String> customAttributes = ConvertStringMap(customAttributesMap);
            builder.customAttributes(customAttributes);
        }

        if (map.hasKey("position")) {
            int position = map.getInt("position");
            builder.position(position);
        }

        if (map.hasKey("quantity")) {
            double quantity = map.getDouble("quantity");
            builder.quantity(quantity);
        }

        if (map.hasKey("variant")) {
            String variant = map.getString("variant");
            builder.variant(variant);
        }

        return builder.build();
    }

    private static TransactionAttributes ConvertTransactionAttributes(ReadableMap map) {
        if (!map.hasKey("transactionId")) {
            return null;
        }

        TransactionAttributes transactionAttributes = new TransactionAttributes(map.getString("transactionId"));

        if (map.hasKey("affiliation")) {
            transactionAttributes.setAffiliation(map.getString("affiliation"));
        }

        if (map.hasKey("revenue")) {
            transactionAttributes.setRevenue(map.getDouble("revenue"));
        }

        if (map.hasKey("shipping")) {
            transactionAttributes.setShipping(map.getDouble("shipping"));
        }

        if (map.hasKey("tax")) {
            transactionAttributes.setTax(map.getDouble("tax"));
        }

        if (map.hasKey("couponCode")) {
            transactionAttributes.setCouponCode(map.getString("couponCode"));
        }

        return transactionAttributes;
    }

    private static Promotion ConvertPromotion(ReadableMap map) {
        Promotion promotion = new Promotion();

        if (map.hasKey("id")) {
            promotion.setId(map.getString("id"));
        }

        if (map.hasKey("name")) {
            promotion.setName(map.getString("name"));
        }

        if (map.hasKey("creative")) {
            promotion.setCreative(map.getString("creative"));
        }

        if (map.hasKey("position")) {
            promotion.setPosition(map.getString("position"));
        }

        return promotion;
    }

    private static Impression ConvertImpression(ReadableMap map) {

        String listName = map.getString("impressionListName");
        ReadableArray productsArray = map.getArray("products");
        ReadableMap productMap = productsArray.getMap(0);
        Product product = ConvertProduct(productMap);
        Impression impression = new Impression(listName, product);

        for (int i = 1; i < productsArray.size(); ++i) {
            productMap = productsArray.getMap(i);
            product = ConvertProduct(productMap);
            impression.addProduct(product);
        }

        return impression;
    }

    private static Map<String, String> ConvertStringMap(ReadableMap readableMap) {
        Map<String, String> map = null;

        if (readableMap != null) {
            map = new HashMap<String, String>();
            ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
            while (iterator.hasNextKey()) {
                String key = iterator.nextKey();
                switch (readableMap.getType(key)) {
                    case Null:
                        map.put(key, null);
                        break;
                    case Boolean:
                        map.put(key, Boolean.valueOf(readableMap.getBoolean(key)).toString());
                        break;
                    case Number:
                        try {
                            map.put(key, Integer.toString(readableMap.getInt(key)));
                        } catch (Exception e) {
                            try {
                                map.put(key, Double.toString(readableMap.getDouble(key)));
                            } catch (Exception ex) {
                                Logger.warning("Unable to parse value for \"" + key + "\"");
                            }
                        }
                        break;
                    case String:
                        map.put(key, readableMap.getString(key));
                        break;
                    case Map:
                        Logger.warning("Maps are not supported Attribute value types");
                        break;
                    case Array:
                        Logger.warning("Lists are not supported Attribute value types");
                        break;
                }
            }
        }

        return map;
    }

    private static Map<MParticle.IdentityType, String> ConvertUserIdentities(ReadableMap readableMap) {
        Map<MParticle.IdentityType, String> map = new HashMap<>();
        if (readableMap != null) {
            ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
            while (iterator.hasNextKey()) {
                MParticle.IdentityType identity;
                String key = iterator.nextKey();
                if ("email".equals(key)) {
                    identity = MParticle.IdentityType.Email;
                } else if ("customerId".equals(key)) {
                    identity = MParticle.IdentityType.CustomerId;
                } else {
                    identity = MParticle.IdentityType.parseInt(Integer.parseInt(key));
                }
                if (identity != null) {
                    map.put(identity, readableMap.getString(key));
                }
            }
        }
        return map;
    }

    private WritableMap ConvertToUserIdentities(Map<MParticle.IdentityType, String> userIdentities) {
        WritableMap nativeMap = getWritableMap();
        for (Map.Entry<MParticle.IdentityType, String> entry: userIdentities.entrySet()) {
            nativeMap.putString(String.valueOf(entry.getKey().getValue()), entry.getValue());
        }
        return nativeMap;
    }


    private static MParticle.EventType ConvertEventType(int eventType) {
        switch (eventType) {
            case 1:
                return MParticle.EventType.Navigation;
            case 2:
                return MParticle.EventType.Location;
            case 3:
                return MParticle.EventType.Search;
            case 4:
                return MParticle.EventType.Transaction;
            case 5:
                return MParticle.EventType.UserContent;
            case 6:
                return MParticle.EventType.UserPreference;
            case 7:
                return MParticle.EventType.Social;
            case 8:
                return MParticle.EventType.Other;
            case 9:
                return MParticle.EventType.Media;
            default:
                return MParticle.EventType.Other;
        }
    }

    private static String ConvertProductActionType(int productActionType) {
        switch (productActionType) {
            case 1:
                return Product.ADD_TO_CART;
            case 2:
                return Product.REMOVE_FROM_CART;
            case 3:
                return Product.CHECKOUT;
            case 4:
                return Product.CHECKOUT_OPTION;
            case 5:
                return Product.CLICK;
            case 6:
                return Product.DETAIL;
            case 7:
                return Product.PURCHASE;
            case 8:
                return Product.REFUND;
            case 9:
                return Product.ADD_TO_WISHLIST;
            default:
                return Product.REMOVE_FROM_WISHLIST;
        }
    }

    private static String ConvertPromotionActionType(int promotionActionType) {
        switch (promotionActionType) {
            case 0:
                return Promotion.VIEW;
            default:
                return Promotion.CLICK;
        }
    }

    private boolean isEmpty(String str) {
        return str == null || str.length() == 0;
    }

    private long parseMpid(String longString) {
        try {
            return Long.parseLong(longString);
        } catch (NumberFormatException ex) {
            return 0L;
        }
    }

    @Nullable
    private GDPRConsent ConvertToGDPRConsent(ReadableMap map) {
        Boolean consented;
        try {
            if (map.getType("consented").equals(ReadableType.Boolean)) {
                consented = map.getBoolean("consented");
            } else {
                consented = Boolean.valueOf(map.getString("consented"));
            }
        } catch (Exception ex) {
            Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addGDPRConsentState");
            return null;
        }
        GDPRConsent.Builder builder = GDPRConsent.builder(consented);

        if (map.hasKey("document")) {
            String document = map.getString("document");
            builder.document(document);
        }
        if (map.hasKey("hardwareId")) {
            String hardwareId = map.getString("hardwareId");
            builder.hardwareId(hardwareId);
        }
        if (map.hasKey("location")) {
            String location = map.getString("location");
            builder.location(location);
        }
        if (map.hasKey("timestamp")) {
            Long timestamp = null;
            try {
                String timestampString = map.getString("timestamp");
                timestamp = Long.valueOf(timestampString);
                builder.timestamp(timestamp);
            } catch (Exception ex) {
                Logger.warning("failed to convert \"timestamp\" value to Long");
            }
        }
        return builder.build();
    }

    @Nullable
    private CCPAConsent ConvertToCCPAConsent(ReadableMap map ) {
        Boolean consented;
        try {
            if (map.getType("consented").equals(ReadableType.Boolean)) {
                consented = map.getBoolean("consented");
            } else {
                consented = Boolean.valueOf(map.getString("consented"));
            }
        } catch (Exception ex) {
            Logger.error("failed to convert \"consented\" value to a Boolean, unable to process addCCPAConsentState");
            return null;
        }
        CCPAConsent.Builder builder = CCPAConsent.builder(consented);

        if (map.hasKey("document")) {
            String document = map.getString("document");
            builder.document(document);
        }
        if (map.hasKey("hardwareId")) {
            String hardwareId = map.getString("hardwareId");
            builder.hardwareId(hardwareId);
        }
        if (map.hasKey("location")) {
            String location = map.getString("location");
            builder.location(location);
        }
        if (map.hasKey("timestamp")) {
            Long timestamp = null;
            try {
                String timestampString = map.getString("timestamp");
                timestamp = Long.valueOf(timestampString);
                builder.timestamp(timestamp);
            } catch (Exception ex) {
                Logger.warning("failed to convert \"timestamp\" value to Long");
            }
        }
        return builder.build();
    }
}
