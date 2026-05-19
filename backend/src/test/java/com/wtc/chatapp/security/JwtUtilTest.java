package com.wtc.chatapp.security;

import com.wtc.chatapp.model.Role;
import com.wtc.chatapp.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;

class JwtUtilTest {

    // HS256 requires a key >= 256 bits (32 bytes)
    private static final String SECRET = "wtc-chat-app-secret-key-2026-spring-boot-jwt-authentication-key";

    private JwtUtil jwtUtil;
    private User user;

    @BeforeEach
    void setUp() {
        jwtUtil = newJwtUtil(60_000L, 120_000L);
        user = User.builder().id("u-1").role(Role.OPERATOR).email("admin@wtc.com").build();
    }

    private JwtUtil newJwtUtil(long expiration, long refreshExpiration) {
        JwtUtil util = new JwtUtil();
        ReflectionTestUtils.setField(util, "secret", SECRET);
        ReflectionTestUtils.setField(util, "expiration", expiration);
        ReflectionTestUtils.setField(util, "refreshExpiration", refreshExpiration);
        return util;
    }

    @Test
    void generateToken_roundTripsClaims() {
        String token = jwtUtil.generateToken(user);

        assertThat(token).isNotBlank();
        assertThat(jwtUtil.extractUserId(token)).isEqualTo("u-1");
        assertThat(jwtUtil.extractRole(token)).isEqualTo("OPERATOR");
        assertThat(jwtUtil.extractEmail(token)).isEqualTo("admin@wtc.com");
        assertThat(jwtUtil.isTokenValid(token)).isTrue();
    }

    @Test
    void generateRefreshToken_isValidAndCarriesSubject() {
        String refresh = jwtUtil.generateRefreshToken(user);

        assertThat(jwtUtil.isTokenValid(refresh)).isTrue();
        assertThat(jwtUtil.extractUserId(refresh)).isEqualTo("u-1");
    }

    @Test
    void isTokenValid_garbageToken_returnsFalse() {
        assertThat(jwtUtil.isTokenValid("not.a.jwt")).isFalse();
        assertThat(jwtUtil.isTokenValid("")).isFalse();
    }

    @Test
    void isTokenValid_tokenSignedWithDifferentKey_returnsFalse() {
        JwtUtil otherKey = new JwtUtil();
        ReflectionTestUtils.setField(otherKey, "secret",
                "a-completely-different-secret-key-of-sufficient-length-1234567890");
        ReflectionTestUtils.setField(otherKey, "expiration", 60_000L);
        ReflectionTestUtils.setField(otherKey, "refreshExpiration", 60_000L);
        String foreignToken = otherKey.generateToken(user);

        assertThat(jwtUtil.isTokenValid(foreignToken)).isFalse();
    }

    @Test
    void isTokenValid_expiredToken_returnsFalse() {
        JwtUtil expiring = newJwtUtil(-1_000L, -1_000L); // already expired
        String expired = expiring.generateToken(user);

        assertThat(jwtUtil.isTokenValid(expired)).isFalse();
    }
}
