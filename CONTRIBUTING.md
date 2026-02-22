# Contributing to OpenClaw + SearXNG Tutorial

First off, thank you for considering contributing to this tutorial! It's people like you that make the open source community such a great place to learn, inspire, and create.

## 📋 How to Contribute

### 1. Report Bugs
If you find a bug in the tutorial or setup script:
- Check if the bug hasn't already been reported in [Issues](https://github.com/darksoon/openclaw-searxng/issues)
- If not, open a new issue with:
  - Clear title and description
  - Steps to reproduce
  - Expected vs actual behavior
  - Screenshots if applicable
  - Your environment (OS, Docker version, etc.)

### 2. Suggest Enhancements
Have an idea to improve the tutorial?
- Open an issue with the `enhancement` label
- Describe the feature and why it would be useful
- Include examples if possible

### 3. Submit Pull Requests
1. **Fork** the repository
2. **Create a branch** for your feature/fix:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Test your changes** thoroughly
5. **Commit** with descriptive messages:
   ```bash
   git commit -m "Add amazing feature"
   ```
6. **Push** to your fork:
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

## 🛠️ Development Setup

### Prerequisites
- Docker & Docker Compose
- Git
- Text editor

### Local Development
1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/openclaw-searxng.git
   cd openclaw-searxng
   ```

2. Test the setup script:
   ```bash
   ./scripts/setup.sh
   ```

3. Make changes and test:
   ```bash
   # Clean up test environment
   docker-compose down -v
   rm -rf data cache .env
   
   # Test again
   ./scripts/setup.sh
   ```

## 📝 Writing Guidelines

### Documentation
- Use clear, concise language
- Include code examples where helpful
- Add screenshots for complex steps
- Keep Markdown formatting consistent

### Code Style
- Shell scripts: Use `#!/bin/bash` shebang
- Indentation: 2 spaces for YAML/JSON, 4 spaces for shell
- Comments: Explain why, not what
- Error handling: Always check command success

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Formatting, missing semi-colons, etc.
- `refactor:` Code restructuring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example:
```
feat: add health check monitoring script
fix: correct JSON API enablement command
docs: update Unraid setup instructions
```

## 🧪 Testing

### Test Categories
1. **Setup Script**: Full end-to-end test
2. **Individual Commands**: Each major command
3. **Edge Cases**: Different OS, Docker versions
4. **Error Handling**: Invalid inputs, missing dependencies

### Running Tests
```bash
# Test setup script
./scripts/setup.sh

# Test cleanup
docker-compose down -v
rm -rf data cache .env

# Test specific scenarios
./scripts/test.sh --scenario=unraid
./scripts/test.sh --scenario=linux
```

## 🏷️ Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or improvement
- `documentation`: Documentation improvements
- `question`: Further information is requested
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed

## 📞 Communication

- **Issues**: Use GitHub issues for bugs and features
- **Discussions**: Use GitHub Discussions for questions
- **Pull Requests**: Keep conversations focused on the code

## 🎯 Quality Standards

- All code should be tested
- Documentation should be up-to-date
- Examples should work as shown
- Keep backward compatibility where possible
- Follow security best practices

## 🙏 Thank You!

Your contributions are greatly appreciated. Whether you're fixing a typo or adding a major feature, every bit helps make this tutorial better for everyone.

Happy contributing! 🚀