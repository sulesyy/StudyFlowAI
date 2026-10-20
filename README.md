# StudyFlow AI

StudyFlow AI, ders ve sınav hazırlığını planlamak için SwiftUI ile geliştirilmiş bir iOS uygulamasıdır. Derslerini ve konularını takip eder; AI ile özet, quiz ve çalışma kartları üretir.

## Ekran görüntüleri

| Bugün | Ders detayı | AI çalışma alanı |
|---|---|---|
| ![Bugün ekranı](screenshots/dashboard.png) | ![Ders detayı](screenshots/course-detail.png) | ![AI çalışma alanı](screenshots/ai-workspace.png) |

## Özellikler

- Ders, konu, sınav tarihi ve çalışma planı takibi
- Günlük görevler, ilerleme istatistikleri ve çalışma serisi
- AI ile konu özeti, çoktan seçmeli quiz ve çalışma kartları
- PDF notlarından metin çıkarma; taranmış sayfalarda cihaz üzerinde Apple Vision OCR
- PDF içeriğiyle AI özeti ve sohbet
- Çevrimdışı erişim için oluşturulan içerikleri kaydetme
- Odak zamanlayıcısı, hatırlatıcılar ve yedekleme

## Gereksinimler

- Xcode 16 veya üstü
- iOS 18.2 veya üstü
- AI özellikleri için Node.js 18 veya üstü ve Google AI Studio Gemini API anahtarı

## Xcode ile çalıştırma

1. `StudyFlowAI.xcodeproj` dosyasını Xcode’da aç.
2. `StudyFlowAI` şemasını ve bir iOS Simulator cihazını seçip **Run** düğmesine bas.
3. AI özelliklerini kullanmak için `backend` klasöründeki proxy’yi başlat:

   ```sh
   cd backend
   cp .env.example .env
   ```

4. `backend/.env` dosyasını açıp `GEMINI_API_KEY` satırına kendi anahtarını ekle. Ardından:

   ```sh
   node server.mjs
   ```

5. `http://127.0.0.1:3000/health` adresinde proxy durumunu kontrol et. Terminal penceresi açık kalmalıdır.

API anahtarını kaynak koduna veya GitHub’a ekleme. `backend/.env` Git tarafından yok sayılır; yalnızca `.env.example` örnek dosyasını paylaş.

## Gerçek iPhone’da AI kullanımı

Simülatördeki `127.0.0.1` adresi Mac’e ulaşır; fiziksel iPhone’da ise telefonun kendisini gösterir. Gerçek cihazda AI için proxy’yi HTTPS arkasında barındır ve Xcode’daki `AI_PROXY_URL` ayarını bu HTTPS adresine yönlendir. API anahtarını uygulamaya koyma.

## Yayına hazırlık

`backend/server.mjs` yerel geliştirme proxy’sidir; internete doğrudan açılmamalıdır. Gerçek kullanıcı dağıtımından önce güvenli HTTPS barındırma, kullanıcı doğrulama ve kötüye kullanım sınırları eklenmelidir. App Store dağıtımı ayrıca gizlilik politikası, mağaza materyalleri ve gerçek cihaz kontrolleri gerektirir.
