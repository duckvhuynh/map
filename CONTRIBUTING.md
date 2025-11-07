# Contributing to Vietnam Map Server

Cảm ơn bạn đã quan tâm đến việc đóng góp cho dự án! Chúng tôi hoan nghênh mọi đóng góp từ cộng đồng.

## Cách đóng góp

### Báo cáo lỗi (Bug Reports)

Nếu bạn tìm thấy lỗi:

1. Kiểm tra [Issues](https://github.com/yourname/vietnam-map-server/issues) xem lỗi đã được báo cáo chưa
2. Nếu chưa, tạo issue mới với thông tin:
   - Mô tả lỗi chi tiết
   - Các bước để tái hiện lỗi
   - Kết quả mong đợi vs kết quả thực tế
   - Môi trường (OS, Docker version, etc.)
   - Logs liên quan

### Đề xuất tính năng (Feature Requests)

1. Tạo issue với label "enhancement"
2. Mô tả rõ tính năng và lý do cần thiết
3. Đưa ra ví dụ use cases

### Pull Requests

1. Fork repository
2. Tạo branch mới: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Tạo Pull Request

#### Quy tắc Pull Request

- Code phải tuân theo coding standards
- Thêm tests nếu có thể
- Update documentation nếu cần
- Đảm bảo tất cả tests pass
- Mô tả rõ ràng những thay đổi

### Code Standards

- **Docker/Shell**: Follow best practices, comment rõ ràng
- **JavaScript/TypeScript**: ESLint, Prettier
- **Python**: PEP 8
- **Documentation**: Markdown, rõ ràng, có ví dụ

## Development Setup

```bash
# Clone repo
git clone https://github.com/yourname/vietnam-map-server.git
cd vietnam-map-server

# Setup development environment
bash scripts/setup.sh

# Make changes
# ...

# Test changes
docker compose up -d
# Test functionality manually or with scripts
```

## Areas needing help

- [ ] Documentation improvements (especially English version)
- [ ] Frontend UI/UX enhancements
- [ ] Performance optimizations
- [ ] Additional routing profiles (motorcycle, bus)
- [ ] Traffic data integration
- [ ] Mobile app examples
- [ ] Docker optimization
- [ ] CI/CD pipelines
- [ ] Tests

## Questions?

- Open an [Issue](https://github.com/yourname/vietnam-map-server/issues)
- Email: your-email@example.com

## Code of Conduct

- Tôn trọng mọi người
- Chấp nhận phản hồi mang tính xây dựng
- Tập trung vào điều tốt nhất cho cộng đồng
- Giúp đỡ người mới

---

Cảm ơn bạn đã đóng góp! 🎉
