package com.example.Ask.Service;

import com.example.Ask.Repositories.AnimalRepository;
import jakarta.persistence.Column;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;
import com.example.Ask.Entities.Animal;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import com.example.Ask.Service.FileStorageService;


@Service
public class AnimalService {
    private AnimalRepository AnimalRepo;
    private AnimalService animalservice;
    @Autowired
    private FileStorageService fileStorageService;
    public AnimalService(AnimalRepository AnimalRepo) {
        this.AnimalRepo = AnimalRepo;
        this.animalservice = this;
    }

    @Transactional
    public List<Animal> getAnimals() {
        return AnimalRepo.findAll();
    }

    @Transactional
    public Animal saveAnimal(Animal animal) {
        AnimalRepo.save(animal);
        return animal;
    }

    @Transactional
    public Animal getAnimal(Integer id) {
        return AnimalRepo.findById(id).get();
    }
    @Transactional
    public void Delanimal(Animal animal) {
        AnimalRepo.delete(animal);
    }


    @Transactional
    public void delAnimal(Integer id) {
        AnimalRepo.deleteById(id);
    }

    /**
     * Επιστρέφει λίστα Animal με ενημερωμένο imageUrl (presigned URL) αν είναι filename
     */
    @Transactional
    public List<Animal> getAnimalsWithPresignedUrls() {
        List<Animal> animals = AnimalRepo.findAll();
        for (Animal animal : animals) {
            if (animal.getImageUrl() != null && !animal.getImageUrl().startsWith("http")) {
                String presignedUrl = fileStorageService.generatePublicUrl(animal.getImageUrl());
                animal.setImageUrl(presignedUrl);
            }
        }
        return animals;
    }

    /**
     * Επιστρέφει ένα Animal με ενημερωμένο imageUrl (presigned URL) αν είναι filename
     */
    @Transactional
    public Animal getAnimalWithPresignedUrl(Animal animal) {
        if (animal != null && animal.getImageUrl() != null && !animal.getImageUrl().startsWith("http")) {
            String presignedUrl = fileStorageService.generatePublicUrl(animal.getImageUrl());
            animal.setImageUrl(presignedUrl);
        }
        return animal;
    }
}



