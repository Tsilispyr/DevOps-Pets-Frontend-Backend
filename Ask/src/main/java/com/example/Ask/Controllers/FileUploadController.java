package com.example.Ask.Controllers;

import com.example.Ask.Entities.Animal;
import com.example.Ask.Service.AnimalService;
import com.example.Ask.Service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@CrossOrigin(origins = "*")
public class FileUploadController {

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private AnimalService animalService;

    @PostMapping("/upload")
    public ResponseEntity<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
        try {
            String imageUrl = fileStorageService.uploadImage(file);
            
            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("message", "File uploaded successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", "Failed to upload file: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @PostMapping("/upload-animal-image/{animalId}")
    public ResponseEntity<Map<String, String>> uploadAnimalImage(
            @PathVariable Integer animalId,
            @RequestParam("file") MultipartFile file) {
        try {
            // Upload image to MinIO
            String imageUrl = fileStorageService.uploadImage(file);
            
            // Update animal record with image URL
            Animal animal = animalService.getAnimal(animalId);
            if (animal != null) {
                animal.setImageUrl(imageUrl);
                animalService.saveAnimal(animal);
                
                Map<String, String> response = new HashMap<>();
                response.put("imageUrl", imageUrl);
                response.put("message", "Animal image uploaded successfully");
                
                return ResponseEntity.ok(response);
            } else {
                Map<String, String> response = new HashMap<>();
                response.put("error", "Animal not found");
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", "Failed to upload animal image: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    @DeleteMapping("/delete/{filename}")
    public ResponseEntity<Map<String, String>> deleteFile(@PathVariable String filename) {
        try {
            fileStorageService.deleteImage(filename);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "File deleted successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", "Failed to delete file: " + e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
} 