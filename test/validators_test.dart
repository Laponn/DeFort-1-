import 'package:flutter_test/flutter_test.dart';
import 'package:defort/core/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error for empty email', () {
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
        expect(Validators.email('  '), isNotNull);
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('abc'), isNotNull);
        expect(Validators.email('abc@'), isNotNull);
        expect(Validators.email('@example.com'), isNotNull);
        expect(Validators.email('abc@.com'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.email('user@example.com'), isNull);
        expect(Validators.email('test.user@domain.co.id'), isNull);
        expect(Validators.email('hello@test.org'), isNull);
      });
    });

    group('password', () {
      test('returns error for empty password', () {
        expect(Validators.password(''), isNotNull);
        expect(Validators.password(null), isNotNull);
      });

      test('returns error for short password', () {
        expect(Validators.password('123'), isNotNull);
        expect(Validators.password('ab'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(Validators.password('password'), isNull);
        expect(Validators.password('123456'), isNull);
      });
    });

    group('passwordStrong', () {
      test('returns error for short password', () {
        expect(Validators.passwordStrong('Pass1'), isNotNull);
      });

      test('returns error for missing uppercase', () {
        expect(Validators.passwordStrong('password123'), isNotNull);
      });

      test('returns error for missing number', () {
        expect(Validators.passwordStrong('Password'), isNotNull);
      });

      test('returns null for strong password', () {
        expect(Validators.passwordStrong('Password1'), isNull);
        expect(Validators.passwordStrong('MySecure99'), isNull);
      });
    });

    group('confirmPassword', () {
      test('returns error when passwords dont match', () {
        expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
      });

      test('returns error for empty confirm', () {
        expect(Validators.confirmPassword('', 'password'), isNotNull);
        expect(Validators.confirmPassword(null, 'password'), isNotNull);
      });

      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('password', 'password'), isNull);
      });
    });

    group('name', () {
      test('returns error for empty name', () {
        expect(Validators.name(''), isNotNull);
        expect(Validators.name(null), isNotNull);
        expect(Validators.name(' '), isNotNull);
      });

      test('returns error for single char name', () {
        expect(Validators.name('A'), isNotNull);
      });

      test('returns null for valid name', () {
        expect(Validators.name('John'), isNull);
        expect(Validators.name('Jane Doe'), isNull);
      });
    });

    group('phone', () {
      test('returns error for empty phone', () {
        expect(Validators.phone(''), isNotNull);
        expect(Validators.phone(null), isNotNull);
      });

      test('returns error for invalid phone', () {
        expect(Validators.phone('abc'), isNotNull);
        expect(Validators.phone('12'), isNotNull);
      });

      test('returns null for valid phone', () {
        expect(Validators.phone('+62 812-3456-7890'), isNull);
        expect(Validators.phone('08123456789'), isNull);
      });
    });

    group('url', () {
      test('returns error for empty URL', () {
        expect(Validators.url(''), isNotNull);
        expect(Validators.url(null), isNotNull);
      });

      test('returns error for invalid URL', () {
        expect(Validators.url('abc'), isNotNull);
        expect(Validators.url('example.com'), isNotNull);
        expect(Validators.url('ftp://test.com'), isNotNull);
      });

      test('returns null for valid URL', () {
        expect(Validators.url('https://example.com'), isNull);
        expect(Validators.url('http://test.org/path'), isNull);
        expect(Validators.url('https://sub.domain.co.id/page?q=1'), isNull);
      });
    });

    group('required', () {
      test('returns error for empty value', () {
        expect(Validators.required(''), isNotNull);
        expect(Validators.required(null), isNotNull);
        expect(Validators.required('  '), isNotNull);
      });

      test('returns null for non-empty value', () {
        expect(Validators.required('hello'), isNull);
      });
    });
  });
}
