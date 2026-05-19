package com.wtc.chatapp.audit;

import com.wtc.chatapp.service.AuditService;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.lang.reflect.Method;

@Aspect
@Component
public class AuditAspect {

    private final AuditService auditService;

    public AuditAspect(AuditService auditService) {
        this.auditService = auditService;
    }

    @AfterReturning(
            pointcut = "within(com.wtc.chatapp.controller..*) && " +
                    "(@annotation(org.springframework.web.bind.annotation.PostMapping) || " +
                    "@annotation(org.springframework.web.bind.annotation.PutMapping) || " +
                    "@annotation(org.springframework.web.bind.annotation.DeleteMapping))",
            returning = "result"
    )
    public void auditAction(JoinPoint joinPoint, Object result) {
        try {
            String userId = "anonymous";
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() != null) {
                userId = auth.getPrincipal().toString();
            }

            String action = determineAction(joinPoint);
            String resource = joinPoint.getTarget().getClass().getSimpleName().replace("Controller", "").toLowerCase();
            String resourceId = extractResourceId(joinPoint);
            String ipAddress = getClientIp();

            String details = joinPoint.getSignature().getName();

            auditService.log(userId, action, resource, resourceId, details, ipAddress);
        } catch (Exception e) {
            // Audit logging should never break the main flow
        }
    }

    private String determineAction(JoinPoint joinPoint) {
        try {
            Method method = getMethod(joinPoint);
            if (method.isAnnotationPresent(PostMapping.class)) return "CREATE";
            if (method.isAnnotationPresent(PutMapping.class)) return "UPDATE";
            if (method.isAnnotationPresent(DeleteMapping.class)) return "DELETE";
        } catch (Exception ignored) {}
        return "UNKNOWN";
    }

    private Method getMethod(JoinPoint joinPoint) throws NoSuchMethodException {
        String methodName = joinPoint.getSignature().getName();
        Class<?>[] paramTypes = new Class[joinPoint.getArgs().length];
        for (int i = 0; i < joinPoint.getArgs().length; i++) {
            paramTypes[i] = joinPoint.getArgs()[i] != null ? joinPoint.getArgs()[i].getClass() : Object.class;
        }

        for (Method m : joinPoint.getTarget().getClass().getMethods()) {
            if (m.getName().equals(methodName) && m.getParameterCount() == joinPoint.getArgs().length) {
                return m;
            }
        }
        throw new NoSuchMethodException(methodName);
    }

    private String extractResourceId(JoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();
        for (Object arg : args) {
            if (arg instanceof String s && s.length() == 36) {
                return s;
            }
        }
        return null;
    }

    private String getClientIp() {
        try {
            ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs != null) {
                HttpServletRequest request = attrs.getRequest();
                String xff = request.getHeader("X-Forwarded-For");
                return xff != null ? xff.split(",")[0].trim() : request.getRemoteAddr();
            }
        } catch (Exception ignored) {}
        return null;
    }
}
