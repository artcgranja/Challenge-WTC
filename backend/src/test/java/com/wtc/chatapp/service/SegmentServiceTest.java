package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.SegmentRequest;
import com.wtc.chatapp.model.Segment;
import com.wtc.chatapp.repository.SegmentRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SegmentServiceTest {

    @Mock SegmentRepository segmentRepository;
    @InjectMocks SegmentService segmentService;

    @Test
    void list_delegatesToRepository() {
        List<Segment> all = List.of(Segment.builder().id("s").build());
        when(segmentRepository.findAll()).thenReturn(all);
        assertThat(segmentService.list()).isEqualTo(all);
    }

    @Test
    void getById_found_returnsSegment() {
        Segment s = Segment.builder().id("s-1").name("VIP").build();
        when(segmentRepository.findById("s-1")).thenReturn(Optional.of(s));
        assertThat(segmentService.getById("s-1")).isSameAs(s);
    }

    @Test
    void getById_missing_throwsNotFound() {
        when(segmentRepository.findById("nope")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> segmentService.getById("nope"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void create_buildsSegmentWithCreator() {
        SegmentRequest req = new SegmentRequest();
        req.setName("VIP");
        req.setDescription("Clientes VIP");
        req.setTags(List.of("vip"));
        when(segmentRepository.save(any(Segment.class))).thenAnswer(i -> i.getArgument(0));

        Segment created = segmentService.create(req, "admin-1");

        assertThat(created.getName()).isEqualTo("VIP");
        assertThat(created.getDescription()).isEqualTo("Clientes VIP");
        assertThat(created.getTags()).containsExactly("vip");
        assertThat(created.getCreatedBy()).isEqualTo("admin-1");
    }

    @Test
    void update_existing_updatesFieldsAndTimestamp() {
        Segment existing = Segment.builder().id("s-1").name("Old").description("old").tags(List.of("a")).build();
        when(segmentRepository.findById("s-1")).thenReturn(Optional.of(existing));
        when(segmentRepository.save(any(Segment.class))).thenAnswer(i -> i.getArgument(0));
        SegmentRequest req = new SegmentRequest();
        req.setName("New");
        req.setDescription("new desc");
        req.setTags(List.of("b", "c"));

        Segment updated = segmentService.update("s-1", req);

        assertThat(updated.getName()).isEqualTo("New");
        assertThat(updated.getDescription()).isEqualTo("new desc");
        assertThat(updated.getTags()).containsExactly("b", "c");
        assertThat(updated.getUpdatedAt()).isNotNull();
    }

    @Test
    void update_missing_throwsNotFound() {
        when(segmentRepository.findById("nope")).thenReturn(Optional.empty());
        SegmentRequest req = new SegmentRequest();
        req.setName("x");
        req.setTags(List.of("t"));
        assertThatThrownBy(() -> segmentService.update("nope", req))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void delete_delegatesToRepository() {
        segmentService.delete("s-1");
        ArgumentCaptor<String> idCaptor = ArgumentCaptor.forClass(String.class);
        verify(segmentRepository).deleteById(idCaptor.capture());
        assertThat(idCaptor.getValue()).isEqualTo("s-1");
    }
}
