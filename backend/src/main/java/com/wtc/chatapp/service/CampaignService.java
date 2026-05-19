package com.wtc.chatapp.service;

import com.wtc.chatapp.dto.CampaignRequest;
import com.wtc.chatapp.dto.MessageRequest;
import com.wtc.chatapp.model.Campaign;
import com.wtc.chatapp.model.CampaignStatus;
import com.wtc.chatapp.model.Segment;
import com.wtc.chatapp.model.User;
import com.wtc.chatapp.model.Role;
import com.wtc.chatapp.repository.CampaignRepository;
import com.wtc.chatapp.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;

@Service
public class CampaignService {

    private final CampaignRepository campaignRepository;
    private final SegmentService segmentService;
    private final MessageService messageService;
    private final UserRepository userRepository;

    public CampaignService(CampaignRepository campaignRepository, SegmentService segmentService,
                           MessageService messageService, UserRepository userRepository) {
        this.campaignRepository = campaignRepository;
        this.segmentService = segmentService;
        this.messageService = messageService;
        this.userRepository = userRepository;
    }

    public List<Campaign> list() {
        List<Campaign> campaigns = campaignRepository.findAllByOrderByCreatedAtDesc();
        for (Campaign c : campaigns) {
            if (c.getSentBy() != null && c.getSentBy().length() > 30) {
                userRepository.findById(c.getSentBy())
                        .ifPresent(u -> c.setSentBy(u.getFullName()));
            }
        }
        return campaigns;
    }

    public Campaign create(CampaignRequest request, String operatorId) {
        String operatorName = userRepository.findById(operatorId)
                .map(User::getFullName).orElse(operatorId);
        Campaign campaign = Campaign.builder()
                .name(request.getName())
                .segmentId(request.getSegmentId())
                .content(request.getContent())
                .deeplink(request.getDeeplink())
                .sentBy(operatorName)
                .build();
        return campaignRepository.save(campaign);
    }

    public Campaign send(String campaignId, String operatorId) {
        Campaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Campaign not found"));

        if (campaign.getStatus() == CampaignStatus.SENT) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Campaign already sent");
        }

        Segment segment = segmentService.getById(campaign.getSegmentId());

        MessageRequest msgRequest = new MessageRequest();
        msgRequest.setType("CAMPAIGN");
        msgRequest.setSegmentTags(segment.getTags());
        msgRequest.setContent(campaign.getContent());

        messageService.sendMessage(msgRequest, operatorId);

        long recipientCount = userRepository.findAll().stream()
                .filter(u -> u.getRole() == Role.CLIENT)
                .filter(u -> u.getTags() != null && u.getTags().stream()
                        .anyMatch(tag -> segment.getTags().contains(tag)))
                .count();

        campaign.setStatus(CampaignStatus.SENT);
        campaign.setSentAt(Instant.now());
        String operatorName = userRepository.findById(operatorId)
                .map(User::getFullName).orElse(operatorId);
        campaign.setSentBy(operatorName);
        campaign.setMessageCount((int) recipientCount);
        return campaignRepository.save(campaign);
    }
}
