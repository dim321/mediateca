<!--
  Sync Impact Report:
  Version change: N/A → 1.0.0
  Modified principles: N/A (initial creation)
  Added sections:
    - I. Code Quality Standards
    - II. Testing Standards (NON-NEGOTIABLE)
    - III. User Experience Consistency
    - IV. Performance Requirements
    - Development Workflow
    - Quality Gates
  Removed sections: N/A
  Templates requiring updates:
    - ✅ plan-template.md (Constitution Check section aligned)
    - ✅ spec-template.md (Success Criteria aligned with performance requirements)
    - ✅ tasks-template.md (Test tasks aligned with testing standards)
  Follow-up TODOs: None
-->

# Mediateca Constitution

## Core Principles

### I. Code Quality Standards

**MUST**: All code MUST adhere to Ruby Style Guide and RuboCop configuration. Code MUST be self-documenting with clear, meaningful names. Functions MUST be small, focused on single responsibility. Prefer composition over inheritance. Code MUST pass all linter checks before commit.

**Rationale**: High code quality reduces technical debt, improves maintainability, and enables faster feature development. Consistent style improves team collaboration and code review efficiency.

### II. Testing Standards (NON-NEGOTIABLE)

**MUST**: Test-Driven Development (TDD) is mandatory for all new features. Tests MUST be written before implementation. Red-Green-Refactor cycle MUST be strictly enforced. All tests MUST pass before code review. Test coverage MUST exceed 80% for new code. Integration tests REQUIRED for: new API endpoints, user journeys, inter-service communication, and contract changes.

**MUST**: Use RSpec with FactoryBot for test data. Tests MUST be independent, isolated, and use mocks/stubs for external dependencies. Tests MUST cover typical cases, edge cases, and error conditions. Test descriptions MUST clearly state what is being tested.

**Rationale**: Comprehensive testing prevents regressions, enables confident refactoring, and serves as living documentation. TDD ensures requirements are understood before implementation.

### III. User Experience Consistency

**MUST**: All user-facing features MUST follow consistent design patterns. UI components MUST use Tailwind CSS utility classes following established design system. Hotwire (Turbo and Stimulus) MUST be used for dynamic interactions. Responsive design MUST be implemented for all screens. Error messages MUST be user-friendly and actionable.

**MUST**: User flows MUST be tested from end-user perspective. Accessibility standards (WCAG 2.1 Level AA) MUST be met. Loading states and feedback MUST be provided for all async operations.

**Rationale**: Consistent UX reduces cognitive load, improves user satisfaction, and decreases support burden. Accessible design ensures inclusive access for all users.

### IV. Performance Requirements

**MUST**: Database queries MUST avoid N+1 problems using eager loading (includes, joins, select). Page load times MUST be under 2 seconds for 95th percentile. API endpoints MUST respond within 200ms for 95th percentile. Database indexes MUST be created for all foreign keys and frequently queried columns.

**MUST**: Caching strategies (fragment caching, Russian Doll caching) MUST be implemented for expensive operations. Background jobs MUST be used for time-consuming tasks (>500ms). Memory usage MUST be monitored and optimized. Performance benchmarks MUST be established for critical paths.

**Rationale**: Performance directly impacts user satisfaction and system scalability. Proactive optimization prevents performance degradation as the system grows.

## Development Workflow

**MUST**: All features MUST follow the specification workflow: `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → implementation. Code reviews MUST verify constitution compliance. Breaking changes MUST be documented with migration guides.

**MUST**: Incremental changes MUST be preferred over large rewrites. Each commit MUST represent a logical, testable unit of work. Backwards compatibility MUST be maintained unless explicitly approved.

## Quality Gates

**MUST**: Before merge, code MUST pass:
- All RSpec tests (unit, integration, system)
- RuboCop linting with zero offenses
- Security audit (Brakeman, bundler-audit)
- Performance benchmarks (if applicable)
- Manual UX review for user-facing changes

**MUST**: Constitution violations MUST be justified in Complexity Tracking section of implementation plan. Simpler alternatives MUST be evaluated and documented if rejected.

## Governance

**Constitution Supersedes**: This constitution supersedes all other coding standards and practices. All PRs and code reviews MUST verify compliance with these principles.

**Amendment Procedure**: Amendments require:
1. Documentation of rationale and impact
2. Review and approval from technical lead
3. Update to version number following semantic versioning:
   - MAJOR: Backward incompatible principle removals or redefinitions
   - MINOR: New principle/section added or materially expanded guidance
   - PATCH: Clarifications, wording, typo fixes, non-semantic refinements
4. Propagation to dependent templates and documentation
5. Migration plan if breaking changes affect existing code

**Compliance Review**: Regular compliance reviews MUST be conducted quarterly. Violations MUST be tracked and addressed. Constitution MUST be referenced in all feature planning and code review processes.

**Version**: 1.0.0 | **Ratified**: 2026-02-03 | **Last Amended**: 2026-02-03
