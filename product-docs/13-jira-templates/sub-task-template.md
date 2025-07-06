# Jira Sub-Task Template

## Sub-Task Overview

**Sub-Task Title**: [Insert a clear, specific sub-task title that describes the granular work - Example: "Create user authentication API endpoint"]

**Sub-Task Summary**: [Provide a concise summary of this specific piece of work - Example: "Implement REST API endpoint for user login authentication with JWT token generation"]

## Sub-Task Fields Configuration

### Required Fields

**Issue Type**: Sub-task

**Project**: [Insert project key - Example: PROJ]

**Summary**: [Same as Sub-Task Title above - keep consistent]

**Parent**: [Link to parent issue - REQUIRED for sub-tasks - Example: PROJ-456]

**Description**:
```
## Sub-Task Purpose
[Explain what this sub-task accomplishes within the context of the parent issue - Example: "This sub-task implements the authentication endpoint required for the user login feature, enabling secure user verification and session management"]

## Scope of Work
[Define exactly what work is included in this sub-task - Example: "Create POST /api/auth/login endpoint that accepts email/password, validates credentials against database, and returns JWT token for authenticated users"]

## Technical Details
[Provide specific technical information needed for implementation - Example:
- Accept JSON payload with email and password fields
- Validate input format and required fields
- Query user database for credential verification
- Generate JWT token with 24-hour expiration
- Return appropriate HTTP status codes and response format
- Implement rate limiting for security]

## Acceptance Criteria
[List specific, testable criteria for this sub-task - Example:
- Endpoint accepts POST requests to /api/auth/login
- Valid credentials return 200 status with JWT token
- Invalid credentials return 401 status with error message
- Missing fields return 400 status with validation errors
- Rate limiting prevents brute force attacks
- Response time under 500ms for 95% of requests]

## Dependencies
[List any dependencies specific to this sub-task - Example:
- User database schema must be finalized
- JWT library integration completed
- Rate limiting middleware available
- Authentication service configuration ready]

## Notes
[Any additional context, constraints, or implementation notes - Example: "Follow existing API response format conventions. Use bcrypt for password hashing. Log all authentication attempts for security monitoring"]
```

**Reporter**: [Insert reporter name - typically Tech Lead or person breaking down the parent issue]

**Assignee**: [Insert assignee name - specific developer who will implement this sub-task]

**Priority**: [Usually inherits from parent, but can be adjusted]
- Highest (Critical for parent completion)
- High (Important for parent success)
- Medium (Standard priority)
- Low (Can be deprioritized if needed)

**Labels**: [Add relevant labels for categorization]
- subtask-[type] (Example: subtask-backend)
- parent-[parent-type] (Example: parent-story)
- tech-[technology] (Example: tech-nodejs)
- [specific technical labels]

### Sub-Task Specific Fields

**Story Points**: [Estimate using your team's pointing scale - typically smaller than parent]
- 1: Very simple implementation (few hours)
- 2: Simple implementation (half day)
- 3: Moderate implementation (full day)
- 5: Complex implementation (multiple days)

**Component/s**: [Select specific components this sub-task affects]
- API
- Database
- Frontend Components
- Authentication
- [Other specific areas]

**Fix Version/s**: [Usually inherits from parent - Example: "2025.3.0"]

**Sprint**: [Sprint assignment - typically same as parent or next sprint]

### Additional Context Fields

**Sub-Task Type**: [Category of work being performed]
- Development
- Testing
- Configuration
- Documentation
- Research
- Review
- Bug Fix
- Refactoring

**Technical Area**: [Specific technical domain]
- Frontend Development
- Backend Development
- API Development
- Database Work
- DevOps/Infrastructure
- Testing
- Security
- Performance

**Complexity Level**: [Implementation complexity]
- Simple (Straightforward implementation)
- Medium (Some business logic or integration)
- Complex (Complex logic or multiple dependencies)

## Implementation Guidelines

### Technical Requirements

**Code Standards**:
- Follow team coding conventions and style guide
- Include appropriate error handling and logging
- Write unit tests with minimum coverage requirements
- Document public APIs and complex business logic

**Quality Requirements**:
- Code must pass peer review
- All tests must pass before merge
- No critical security vulnerabilities
- Performance requirements met

### Implementation Steps

**Step-by-Step Approach**:
1. [Step 1] - [Specific action and expected outcome]
2. [Step 2] - [Specific action and expected outcome]
3. [Step 3] - [Specific action and expected outcome]
4. [Step 4] - [Specific action and expected outcome]

**Example for API endpoint sub-task**:
1. Create endpoint route and basic structure
2. Implement request validation and error handling
3. Add database integration for credential verification
4. Implement JWT token generation and response formatting
5. Add unit tests for all scenarios
6. Test integration with existing authentication flow

### Testing Requirements

**Unit Testing**:
- [ ] [Test requirement 1 - Example: Test valid login credentials]
- [ ] [Test requirement 2 - Example: Test invalid credentials handling]
- [ ] [Test requirement 3 - Example: Test input validation]
- [ ] [Test requirement 4 - Example: Test error scenarios]

**Integration Testing**:
- [ ] [Integration test 1 - Example: Test with actual database]
- [ ] [Integration test 2 - Example: Test JWT token validation]
- [ ] [Integration test 3 - Example: Test rate limiting]

## Acceptance Criteria (Detailed)

### Functional Criteria
- [ ] [Functional requirement 1 with specific expected behavior]
- [ ] [Functional requirement 2 with specific expected behavior]
- [ ] [Functional requirement 3 with specific expected behavior]
- [ ] [Functional requirement 4 with specific expected behavior]

### Technical Criteria
- [ ] Code follows established patterns and conventions
- [ ] Unit tests written and passing (minimum 80% coverage)
- [ ] Integration tests implemented where applicable
- [ ] Error handling implemented for all failure scenarios
- [ ] Logging implemented for debugging and monitoring
- [ ] Security best practices followed

### Quality Criteria
- [ ] Code review completed and approved
- [ ] No critical or high-severity bugs
- [ ] Performance requirements met
- [ ] Documentation updated (if applicable)
- [ ] Merge to main branch successful

## Definition of Ready

**Sub-task is ready for implementation when**:
- [ ] Parent issue is clearly understood and approved
- [ ] Sub-task scope is specific and well-defined
- [ ] Technical approach is clear to the developer
- [ ] Dependencies are available or resolved
- [ ] Acceptance criteria are testable and specific
- [ ] Required tools and access are available

## Definition of Done

**Sub-task is complete when**:
- [ ] All acceptance criteria met and verified
- [ ] Code implemented according to technical requirements
- [ ] Unit tests written and passing
- [ ] Integration testing completed (if applicable)
- [ ] Code review completed and approved
- [ ] Documentation updated (if required)
- [ ] Code merged to appropriate branch
- [ ] Parent issue updated with progress

## Common Sub-Task Categories

### Development Sub-Tasks

**Frontend Development**:
- Implement specific UI components
- Add form validation logic
- Create responsive design for specific screens
- Implement client-side routing
- Add accessibility features

**Backend Development**:
- Create specific API endpoints
- Implement business logic functions
- Add database queries or stored procedures
- Create service layer functions
- Implement background jobs or scheduled tasks

**Database Work**:
- Create database schema changes
- Write migration scripts
- Optimize specific queries
- Add database indexes
- Update stored procedures

### Testing Sub-Tasks

**Test Creation**:
- Write unit tests for specific functions
- Create integration test scenarios
- Implement end-to-end test cases
- Add performance test scripts
- Create security test cases

**Test Automation**:
- Set up automated test pipelines
- Configure test environments
- Implement test data management
- Add test reporting and monitoring

### Configuration Sub-Tasks

**Environment Setup**:
- Configure development environment
- Set up staging environment
- Update production configuration
- Configure monitoring and alerting

**Integration Configuration**:
- Configure third-party service integration
- Set up API authentication
- Configure message queues
- Set up caching layers

## Sub-Task Best Practices

### Sizing Guidelines
- Sub-tasks should be completable within 1-3 days
- If larger, consider breaking into smaller sub-tasks
- Each sub-task should have a single, clear purpose
- Avoid sub-tasks that span multiple technical areas

### Communication
- Update progress regularly (daily standups)
- Communicate blockers immediately
- Ask questions early rather than making assumptions
- Coordinate with team members on shared dependencies

### Quality Focus
- Prioritize quality over speed
- Follow team's definition of done strictly
- Seek code review feedback actively
- Test thoroughly before marking complete

---

## Template Usage Instructions

### When to Create Sub-Tasks
1. **Complex Parent Issues**: Break down large stories or tasks into manageable pieces
2. **Parallel Work**: Enable multiple team members to work on different aspects
3. **Different Skill Sets**: Separate work requiring different expertise
4. **Clear Dependencies**: Sequence work that must happen in specific order

### Creating Effective Sub-Tasks
1. **Single Responsibility**: Each sub-task should have one clear purpose
2. **Specific Scope**: Avoid vague or overly broad sub-task definitions
3. **Clear Deliverables**: Make it obvious when the sub-task is complete
4. **Appropriate Size**: Keep sub-tasks small enough for quick completion

### Managing Sub-Tasks
1. **Regular Updates**: Keep parent issue updated as sub-tasks complete
2. **Dependency Management**: Coordinate sub-tasks with dependencies
3. **Progress Tracking**: Monitor overall parent issue progress
4. **Quality Assurance**: Ensure individual sub-tasks integrate properly

### Common Pitfalls to Avoid
- Creating sub-tasks that are too large or complex
- Unclear acceptance criteria or scope
- Missing dependencies between sub-tasks
- Not updating parent issue progress
- Creating unnecessary sub-tasks for simple work

---

**Template Version**: 1.0
**Last Updated**: 2025-07-05
**Template Owner**: [Insert Development Team Lead]
**Next Review**: [Insert review date 90 days from creation]