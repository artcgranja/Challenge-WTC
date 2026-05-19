package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.AuthResponse;
import com.wtc.chatapp.dto.LoginRequest;
import com.wtc.chatapp.dto.RegisterRequest;
import com.wtc.chatapp.model.Role;
import com.wtc.chatapp.model.User;
import com.wtc.chatapp.repository.UserRepository;
import com.wtc.chatapp.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtUtil jwtUtil;
    @InjectMocks AuthService authService;

    private User existing;

    @BeforeEach
    void setUp() {
        existing = User.builder()
                .id("u-1").email("joao@test.com").password("hashed")
                .fullName("João Silva").phone("(11) 1").role(Role.CLIENT)
                .tags(List.of("vip")).status("active").build();
    }

    private void stubTokens() {
        lenient().when(jwtUtil.generateToken(any())).thenReturn("access-tok");
        lenient().when(jwtUtil.generateRefreshToken(any())).thenReturn("refresh-tok");
    }

    // ---------- register ----------

    @Test
    void register_persistsUserAndReturnsTokens() {
        stubTokens();
        RegisterRequest req = new RegisterRequest();
        req.setEmail("new@test.com");
        req.setPassword("secret");
        req.setFullName("New User");
        when(userRepository.existsByEmail("new@test.com")).thenReturn(false);
        when(passwordEncoder.encode("secret")).thenReturn("ENC");
        when(userRepository.save(any(User.class))).thenAnswer(i -> {
            User u = i.getArgument(0);
            u.setId("u-new");
            return u;
        });

        AuthResponse res = authService.register(req);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        User saved = captor.getValue();
        assertThat(saved.getPassword()).isEqualTo("ENC");
        assertThat(saved.getRole()).isEqualTo(Role.CLIENT);
        assertThat(saved.getTags()).isEmpty();
        assertThat(res.getToken()).isEqualTo("access-tok");
        assertThat(res.getRefreshToken()).isEqualTo("refresh-tok");
        assertThat(res.getEmail()).isEqualTo("new@test.com");
    }

    @Test
    void register_duplicateEmail_throwsConflict() {
        RegisterRequest req = new RegisterRequest();
        req.setEmail("joao@test.com");
        req.setPassword("x");
        req.setFullName("Dup");
        when(userRepository.existsByEmail("joao@test.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void register_invalidRole_fallsBackToClient() {
        stubTokens();
        RegisterRequest req = new RegisterRequest();
        req.setEmail("x@test.com");
        req.setPassword("p");
        req.setFullName("X");
        req.setRole("SUPERADMIN");
        when(userRepository.existsByEmail("x@test.com")).thenReturn(false);
        when(passwordEncoder.encode("p")).thenReturn("E");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));

        authService.register(req);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(Role.CLIENT);
    }

    @Test
    void register_operatorRole_isParsedCaseInsensitive() {
        stubTokens();
        RegisterRequest req = new RegisterRequest();
        req.setEmail("op@test.com");
        req.setPassword("p");
        req.setFullName("Op");
        req.setRole("operator");
        when(userRepository.existsByEmail("op@test.com")).thenReturn(false);
        when(passwordEncoder.encode("p")).thenReturn("E");
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));

        authService.register(req);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(Role.OPERATOR);
    }

    // ---------- login ----------

    @Test
    void login_validCredentials_returnsMappedResponse() {
        stubTokens();
        LoginRequest req = new LoginRequest();
        req.setEmail("joao@test.com");
        req.setPassword("plain");
        when(userRepository.findByEmail("joao@test.com")).thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("plain", "hashed")).thenReturn(true);

        AuthResponse res = authService.login(req);

        assertThat(res.getUserId()).isEqualTo("u-1");
        assertThat(res.getEmail()).isEqualTo("joao@test.com");
        assertThat(res.getFullName()).isEqualTo("João Silva");
        assertThat(res.getRole()).isEqualTo("CLIENT");
        assertThat(res.getTags()).containsExactly("vip");
        assertThat(res.getStatus()).isEqualTo("active");
        assertThat(res.getPhone()).isEqualTo("(11) 1");
    }

    @Test
    void login_unknownEmail_throwsUnauthorized() {
        LoginRequest req = new LoginRequest();
        req.setEmail("ghost@test.com");
        req.setPassword("x");
        when(userRepository.findByEmail("ghost@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void login_wrongPassword_throwsUnauthorized() {
        LoginRequest req = new LoginRequest();
        req.setEmail("joao@test.com");
        req.setPassword("wrong");
        when(userRepository.findByEmail("joao@test.com")).thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("wrong", "hashed")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    // ---------- refresh ----------

    @Test
    void refresh_validToken_returnsNewTokens() {
        stubTokens();
        when(jwtUtil.isTokenValid("rt")).thenReturn(true);
        when(jwtUtil.extractUserId("rt")).thenReturn("u-1");
        when(userRepository.findById("u-1")).thenReturn(Optional.of(existing));

        AuthResponse res = authService.refresh("rt");

        assertThat(res.getToken()).isEqualTo("access-tok");
        assertThat(res.getUserId()).isEqualTo("u-1");
    }

    @Test
    void refresh_invalidToken_throwsUnauthorized() {
        when(jwtUtil.isTokenValid("bad")).thenReturn(false);

        assertThatThrownBy(() -> authService.refresh("bad"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void refresh_userNotFound_throwsNotFound() {
        when(jwtUtil.isTokenValid("rt")).thenReturn(true);
        when(jwtUtil.extractUserId("rt")).thenReturn("missing");
        when(userRepository.findById("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refresh("rt"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }
}
