package com.mparticle.react;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableMap;
import com.mparticle.MParticle;
import com.mparticle.identity.AliasRequest;
import com.mparticle.identity.IdentityApi;
import com.mparticle.identity.MParticleUser;
import com.mparticle.react.testutils.MockMParticleUser;
import com.mparticle.react.testutils.MockMap;
import com.mparticle.react.testutils.Mutable;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.Random;

import static junit.framework.TestCase.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

@RunWith(MockitoJUnitRunner.class)
public class IdentityApiTest {
    MParticleModule identityApi;
    Random random = new Random();

    @Before
    public void before() {
        MockitoAnnotations.openMocks(this);
        MParticle.setInstance(Mockito.mock(MParticle.class));
        Mockito.when(MParticle.getInstance().Identity()).thenReturn(Mockito.mock(IdentityApi.class));
        Mockito.lenient().when(MParticle.getInstance().Identity().getUser(0L)).thenReturn(null);
        identityApi = new MParticleModule(Mockito.mock(ReactApplicationContext.class));
    }


    @Test
    public void testGetCurrentUser() {
        final Mutable<Boolean> callbackCalled = new Mutable<>(false);
        final Long mockId = random.nextLong();

        MParticleUser mockUser = new MockMParticleUser() {
            @NonNull
            @Override
            public long getId() {
                return mockId;
            }
        };
        Mockito.when(MParticle.getInstance().Identity().getCurrentUser()).thenReturn(mockUser);
        identityApi.getCurrentUserWithCompletion(new Callback() {
            @Override
            public void invoke(Object... args) {
                assertNull(args[0]);
                assertEquals(mockId.toString(), args[1]);
                callbackCalled.value = true;
            }
        });

        assertTrue(callbackCalled.value);
        callbackCalled.value = false;

        Mockito.when(MParticle.getInstance().Identity().getCurrentUser()).thenReturn(null);
        identityApi.getCurrentUserWithCompletion(new Callback() {
            @Override
            public void invoke(Object... args) {
                assertNull(args[0]);
                assertNull(args[1]);
                callbackCalled.value = true;
            }
        });
        assertTrue(callbackCalled.value);
    }


    @Test
    public void testAliasRequest() throws JSONException {
        ArgumentCaptor<AliasRequest> aliasCaptor = ArgumentCaptor.forClass(AliasRequest.class);
        final Mutable<Object[]> callbackResult = new Mutable<>();

        Mockito.when(MParticle.getInstance().Identity().aliasUsers(Mockito.any(AliasRequest.class))).thenReturn(true);

        JSONObject aliasJson = new JSONObject()
                .put("sourceMpid", "1")
                .put("destinationMpid", "2")
                .put("startTime", "3")
                .put("endTime", "4");
        ReadableMap map = new MockMap(aliasJson);

        identityApi.aliasUsers(map, new Callback() {
            @Override
            public void invoke(Object... args) {
                callbackResult.value = args;
            }
        });

        Mockito.verify(MParticle.getInstance().Identity()).aliasUsers(aliasCaptor.capture());
        assertEquals(1, callbackResult.value.length);
        assertEquals(true, callbackResult.value[0]);

        assertEquals(1, aliasCaptor.getValue().getSourceMpid());
        assertEquals(2, aliasCaptor.getValue().getDestinationMpid());
        assertEquals(3, aliasCaptor.getValue().getStartTime());
        assertEquals(4, aliasCaptor.getValue().getEndTime());

        //start time and end time can be longs
        aliasJson
                .put("startTime", 3)
                .put("endTime", 4);
    }

    @Test
    public void testAliasRequestPartial() throws JSONException {
        ArgumentCaptor<AliasRequest> aliasCaptor = ArgumentCaptor.forClass(AliasRequest.class);
        final Mutable<Object[]> callbackResult = new Mutable<>();
        Long startTime = System.currentTimeMillis();

        MParticleUser sourceUser = Mockito.mock(MParticleUser.class);
        Mockito.when(sourceUser.getId()).thenReturn(1L);
        Mockito.when(sourceUser.getFirstSeenTime()).thenReturn(startTime - 200);
        Mockito.when(sourceUser.getLastSeenTime()).thenReturn(startTime - 100L);

        MParticleUser destinationUser = Mockito.mock(MParticleUser.class);
        Mockito.when(destinationUser.getId()).thenReturn(2L);

        Mockito.when(MParticle.getInstance().Identity().getUser(1L)).thenReturn(sourceUser);
        Mockito.when(MParticle.getInstance().Identity().getUser(2L)).thenReturn(destinationUser);

        Mockito.when(MParticle.getInstance().Identity().aliasUsers(Mockito.any(AliasRequest.class))).thenReturn(true);

        JSONObject aliasJson = new JSONObject()
                .put("sourceMpid", "1")
                .put("destinationMpid", "2");
        ReadableMap map = new MockMap(aliasJson);

        identityApi.aliasUsers(map, new Callback() {
            @Override
            public void invoke(Object... args) {
                callbackResult.value = args;
            }
        });

        Mockito.verify(MParticle.getInstance().Identity()).aliasUsers(aliasCaptor.capture());
        assertEquals(1, callbackResult.value.length);
        assertEquals(true, callbackResult.value[0]);

        assertEquals(1, aliasCaptor.getValue().getSourceMpid());
        assertEquals(2, aliasCaptor.getValue().getDestinationMpid());
        assertEquals(startTime - 200, aliasCaptor.getValue().getStartTime());
        assertEquals(startTime - 100, aliasCaptor.getValue().getEndTime());
    }

    @Test
    public void testAliasRejectedReactNative() throws JSONException {
        final Mutable<Object[]> callbackResult = new Mutable<>();
        Callback callback = new Callback() {
            @Override
            public void invoke(Object... args) {
                callbackResult.value = args;
            }
        };

        //MPIDs need to be Strings, this will fail
        JSONObject aliasJson = new JSONObject()
                .put("sourceMpid", 1)
                .put("destinationMpid", "2")
                .put("startTime", "3")
                .put("endTime", "4");

        identityApi.aliasUsers(new MockMap(aliasJson), callback);

        Mockito.lenient().when(MParticle.getInstance().Identity().aliasUsers(Mockito.any(AliasRequest.class))).thenThrow(new RuntimeException("aliasUsers() should not be called"));
        assertEquals(2, callbackResult.value.length);
        assertEquals(false, callbackResult.value[0]);
        assertTrue(((String)callbackResult.value[1]).length() > 5);
        callbackResult.value = null;

        aliasJson
                .put("sourceMpid", "1")
                .put("destinationMpid", 2);

        identityApi.aliasUsers(new MockMap(aliasJson), callback);

        Mockito.lenient().when(MParticle.getInstance().Identity().aliasUsers(Mockito.any(AliasRequest.class))).thenThrow(new RuntimeException("aliasUsers() should not be called"));
        assertEquals(2, callbackResult.value.length);
        assertEquals(false, callbackResult.value[0]);
        assertTrue(((String)callbackResult.value[1]).length() > 5);
        callbackResult.value = null;
    }

    @Test
    public void testAliasRejectedNativeSdk() throws JSONException {
        ArgumentCaptor<AliasRequest> aliasCaptor = ArgumentCaptor.forClass(AliasRequest.class);
        final Mutable<Object[]> callbackResult = new Mutable<>();

        Mockito.when(MParticle.getInstance().Identity().aliasUsers(Mockito.any(AliasRequest.class))).thenReturn(false);

        JSONObject aliasJson = new JSONObject()
                .put("sourceMpid", "1")
                .put("destinationMpid", "2")
                .put("startTime", "3")
                .put("endTime", "4");
        ReadableMap map = new MockMap(aliasJson);

        identityApi.aliasUsers(map, new Callback() {
            @Override
            public void invoke(Object... args) {
                callbackResult.value = args;
            }
        });

        Mockito.verify(MParticle.getInstance().Identity()).aliasUsers(aliasCaptor.capture());
        assertEquals(1, callbackResult.value.length);
        assertEquals(false, callbackResult.value[0]);

        assertEquals(1, aliasCaptor.getValue().getSourceMpid());
        assertEquals(2, aliasCaptor.getValue().getDestinationMpid());
        assertEquals(3, aliasCaptor.getValue().getStartTime());
        assertEquals(4, aliasCaptor.getValue().getEndTime());
    }
}
