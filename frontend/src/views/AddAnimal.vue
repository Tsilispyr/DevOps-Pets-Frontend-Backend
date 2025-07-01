<template>
  <div>
    <h2>Προσθήκη Ζώου</h2>
    <form @submit.prevent="addAnimal">
      <div>
        <label>Όνομα:</label>
        <input v-model="animal.name" required />
      </div>
      <div>
        <label>Είδος:</label>
        <input v-model="animal.type" required />
      </div>
      <div>
        <label>Φύλο:</label>
        <select v-model="animal.gender" required>
          <option value="Male">Αρσενικό</option>
          <option value="Female">Θηλυκό</option>
        </select>
      </div>
      <div>
        <label>Ηλικία:</label>
        <input v-model="animal.age" type="number" min="0" required />
      </div>
      <div>
        <label>Εικόνα:</label>
        <input type="file" @change="onFileChange" accept="image/*" />
      </div>
      <button type="submit">Προσθήκη</button>
      <button type="button" @click="$router.back()">Ακύρωση</button>
    </form>
  </div>
</template>

<script>
import api from '../api';
export default {
  data() {
    return {
      animal: { name: '', type: '', gender: 'Male', age: 0 },
      imageFile: null
    }
  },
  methods: {
    onFileChange(e) {
      this.imageFile = e.target.files[0];
    },
    async addAnimal() {
      try {
        // 1. Δημιουργία ζώου
        const res = await api.post('/animals', this.animal);
        const animalId = res.data.id || res.data.animalId || res.data;
        // 2. Αν υπάρχει εικόνα, κάνε upload
        if (this.imageFile && animalId) {
          const formData = new FormData();
          formData.append('file', this.imageFile);
          await api.post(`/files/upload-animal-image/${animalId}`, formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
          });
        }
        this.$router.push('/animals');
      } catch (e) {
        alert('Σφάλμα προσθήκης ζώου');
      }
    }
  }
}
</script> 