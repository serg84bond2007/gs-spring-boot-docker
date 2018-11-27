package hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class Application {

    @RequestMapping("/")
    public String home() {
        return "Hello Docker World Тест удался";
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
@Bean
public SpringBootMetricsCollector springBootMetricsCollector(Collection<PublicMetrics> publicMetrics) {
    SpringBootMetricsCollector springBootMetricsCollector = new SpringBootMetricsCollector(publicMetrics);
    springBootMetricsCollector.register();
    return springBootMetricsCollector;
}

@Bean
public ServletRegistrationBean servletRegistrationBean() {
    DefaultExports.initialize();
    return new ServletRegistrationBean(new MetricsServlet(), "/prometheus");
}
