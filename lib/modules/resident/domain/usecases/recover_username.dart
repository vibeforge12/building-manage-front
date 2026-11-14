class UsernameChallenge {
  const UsernameChallenge(this.id, this.expiresAt, this.retryAfterSeconds);
  final String id;
  final DateTime expiresAt;
  final int retryAfterSeconds;
}

class RecoveredAccount {
  const RecoveredAccount(this.username, this.buildingName);
  final String username;
  final String buildingName;
}

abstract class UsernameRecoveryRepository {
  Future<UsernameChallenge> request(String name, String phoneNumber);
  Future<List<RecoveredAccount>> verify(String challengeId, String code);
}

class RecoverUsername {
  const RecoverUsername(this.repository);
  final UsernameRecoveryRepository repository;

  Future<UsernameChallenge> request(String name, String phoneNumber) =>
      repository.request(
        name.trim(),
        phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      );

  Future<List<RecoveredAccount>> verify(String challengeId, String code) =>
      repository.verify(challengeId, code.trim());
}
