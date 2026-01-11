import bcrypt from 'bcryptjs';

const passwords = [
  { name: 'Paulo', password: 'Paulo@2026' },
  { name: 'Kaio', password: 'Kaio@2026' }
];

console.log('Gerando hashes...\n');

for (const user of passwords) {
  const hash = await bcrypt.hash(user.password, 12);
  console.log(`Usuário: ${user.name}`);
  console.log(`Senha: ${user.password}`);
  console.log(`Hash: ${hash}`);
  console.log('');
}
