import bcrypt from 'bcryptjs';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new pg.Client({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

// Senha padrão para todos: 123456
const plainPassword = '123456';

async function createTestUsers() {
  try {
    await client.connect();
    console.log('✅ Conectado ao banco de dados\n');

    // Gerar hash da senha
    const passwordHash = await bcrypt.hash(plainPassword, 12);
    console.log('🔐 Senha hash gerada (senha: 123456)\n');

    // 1. Criar ADMIN
    console.log('👤 Criando usuário ADMIN...');
    const adminResult = await client.query(
      `INSERT INTO users (name, email, password_hash, user_type)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE
       SET user_type = $4, password_hash = $3
       RETURNING id, name, email, user_type`,
      ['Administrador Sistema', 'admin@casayme.com', passwordHash, 'ADMIN']
    );
    console.log('✅ ADMIN criado:', adminResult.rows[0]);
    console.log('   Email: admin@casayme.com');
    console.log('   Senha: 123456\n');

    // 2. Criar CORRETOR
    console.log('👤 Criando usuário CORRETOR...');
    const corretorResult = await client.query(
      `INSERT INTO users (name, email, password_hash, user_type, creci, company_name, phone)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO UPDATE
       SET user_type = $4, password_hash = $3, creci = $5, company_name = $6, phone = $7
       RETURNING id, name, email, user_type, creci, company_name, phone`,
      [
        'João Corretor Silva',
        'corretor@casayme.com',
        passwordHash,
        'CORRETOR',
        '12345-SP',
        'Casa YME Imóveis',
        '11999887766'
      ]
    );
    console.log('✅ CORRETOR criado:', corretorResult.rows[0]);
    console.log('   Email: corretor@casayme.com');
    console.log('   Senha: 123456');
    console.log('   CRECI: 12345-SP\n');

    // 3. Criar VISITANTE
    console.log('👤 Criando usuário VISITANTE...');
    const visitanteResult = await client.query(
      `INSERT INTO users (name, email, password_hash, user_type)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE
       SET user_type = $4, password_hash = $3
       RETURNING id, name, email, user_type`,
      ['Maria Cliente Santos', 'visitante@casayme.com', passwordHash, 'VISITANTE']
    );
    console.log('✅ VISITANTE criado:', visitanteResult.rows[0]);
    console.log('   Email: visitante@casayme.com');
    console.log('   Senha: 123456\n');

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 TODOS OS USUÁRIOS CRIADOS COM SUCESSO!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('📋 RESUMO DOS LOGINS:\n');
    console.log('🔴 ADMIN:');
    console.log('   Email: admin@casayme.com');
    console.log('   Senha: 123456');
    console.log('   Pode: Ver, Criar, Editar, Deletar TODOS os imóveis\n');

    console.log('🟢 CORRETOR:');
    console.log('   Email: corretor@casayme.com');
    console.log('   Senha: 123456');
    console.log('   CRECI: 12345-SP');
    console.log('   Pode: Ver, Criar, Editar, Deletar seus próprios imóveis\n');

    console.log('🔵 VISITANTE:');
    console.log('   Email: visitante@casayme.com');
    console.log('   Senha: 123456');
    console.log('   Pode: Ver imóveis, Favoritar, Criar Alertas\n');

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🌐 Acesse: http://localhost:5175');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    await client.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao criar usuários:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

createTestUsers();
