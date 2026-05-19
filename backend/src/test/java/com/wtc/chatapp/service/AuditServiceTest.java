package com.wtc.chatapp.service;

import com.wtc.chatapp.model.AuditLog;
import com.wtc.chatapp.repository.AuditLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuditServiceTest {

    @Mock AuditLogRepository auditLogRepository;
    @InjectMocks AuditService auditService;

    @Test
    void log_buildsAndPersistsAuditLog() {
        auditService.log("u-1", "CREATE", "messages", "m-1", "details", "127.0.0.1");

        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        AuditLog saved = captor.getValue();
        assertThat(saved.getUserId()).isEqualTo("u-1");
        assertThat(saved.getAction()).isEqualTo("CREATE");
        assertThat(saved.getResource()).isEqualTo("messages");
        assertThat(saved.getResourceId()).isEqualTo("m-1");
        assertThat(saved.getDetails()).isEqualTo("details");
        assertThat(saved.getIpAddress()).isEqualTo("127.0.0.1");
        assertThat(saved.getTimestamp()).isNotNull();
    }

    @Test
    void list_byResource_usesResourceQuery() {
        List<AuditLog> expected = List.of(AuditLog.builder().id("a").build());
        when(auditLogRepository.findByResourceOrderByTimestampDesc("messages")).thenReturn(expected);

        assertThat(auditService.list("messages", null)).isEqualTo(expected);
        verify(auditLogRepository, never()).findAllByOrderByTimestampDesc();
    }

    @Test
    void list_byUserId_usesUserQuery() {
        List<AuditLog> expected = List.of(AuditLog.builder().id("a").build());
        when(auditLogRepository.findByUserIdOrderByTimestampDesc("u-1")).thenReturn(expected);

        assertThat(auditService.list(null, "u-1")).isEqualTo(expected);
    }

    @Test
    void list_noFilters_returnsAll() {
        List<AuditLog> expected = List.of(AuditLog.builder().id("a").build());
        when(auditLogRepository.findAllByOrderByTimestampDesc()).thenReturn(expected);

        assertThat(auditService.list(null, null)).isEqualTo(expected);
    }

    @Test
    void list_resourceTakesPrecedenceOverUserId() {
        List<AuditLog> byResource = List.of(AuditLog.builder().id("r").build());
        when(auditLogRepository.findByResourceOrderByTimestampDesc("messages")).thenReturn(byResource);

        assertThat(auditService.list("messages", "u-1")).isEqualTo(byResource);
        verify(auditLogRepository, never()).findByUserIdOrderByTimestampDesc("u-1");
    }
}
