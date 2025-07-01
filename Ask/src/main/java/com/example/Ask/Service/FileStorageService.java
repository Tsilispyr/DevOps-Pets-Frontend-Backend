package com.example.Ask.Service;

import com.example.Ask.config.MinioConfig;
import io.minio.*;
import io.minio.http.Method;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class FileStorageService {

    @Autowired
    private MinioClient minioClient;

    @Autowired
    private MinioConfig minioConfig;

    public String uploadImage(MultipartFile file) {
        try {
            // Generate unique filename
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            String filename = UUID.randomUUID().toString() + extension;

            // Upload file to MinIO
            minioClient.putObject(
                PutObjectArgs.builder()
                    .bucket(minioConfig.getBucket())
                    .object(filename)
                    .stream(file.getInputStream(), file.getSize(), -1)
                    .contentType(file.getContentType())
                    .build()
            );

            // Generate public URL
            return generatePublicUrl(filename);

        } catch (Exception e) {
            throw new RuntimeException("Failed to upload image: " + e.getMessage(), e);
        }
    }

    public String generatePublicUrl(String filename) {
        try {
            // Generate presigned URL for public access (valid for 7 days)
            return minioClient.getPresignedObjectUrl(
                GetPresignedObjectUrlArgs.builder()
                    .method(Method.GET)
                    .bucket(minioConfig.getBucket())
                    .object(filename)
                    .expiry(7, TimeUnit.DAYS)
                    .build()
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate public URL: " + e.getMessage(), e);
        }
    }

    public void deleteImage(String filename) {
        try {
            minioClient.removeObject(
                RemoveObjectArgs.builder()
                    .bucket(minioConfig.getBucket())
                    .object(filename)
                    .build()
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete image: " + e.getMessage(), e);
        }
    }

    public boolean imageExists(String filename) {
        try {
            minioClient.statObject(
                StatObjectArgs.builder()
                    .bucket(minioConfig.getBucket())
                    .object(filename)
                    .build()
            );
            return true;
        } catch (Exception e) {
            return false;
        }
    }
} 