package com.example.MyWebApp;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "--Hello customer❤️! My Spring Boot Application is Running Successfully❤️--";
    }
}
