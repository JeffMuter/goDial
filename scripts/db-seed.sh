#!/usr/bin/env bash

# goDial Database Seeder
# Populates the database with test data for development

set -e

echo "🌱 goDial Database Seeder"
echo "========================="

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DB_PATH="${GODIAL_DB_PATH:-goDial.db}"

echo -e "${BLUE}📊 Database: $DB_PATH${NC}"
echo ""

# Check if database file exists
if [ ! -f "$DB_PATH" ]; then
    echo -e "${RED}❌ Database file not found: $DB_PATH${NC}"
    echo -e "${YELLOW}💡 Run 'db-migrate' to create and initialize the database${NC}"
    exit 1
fi

# Check if data already exists
USER_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM users;")
CALL_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM calls;")

if [ "$USER_COUNT" -gt 0 ] || [ "$CALL_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Database already contains data:${NC}"
    echo -e "${BLUE}   Users: $USER_COUNT${NC}"
    echo -e "${BLUE}   Calls: $CALL_COUNT${NC}"
    echo ""
    
    if [[ "$1" != "--force" ]]; then
        read -p "Do you want to add more test data? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🛑 Seeding cancelled${NC}"
            exit 0
        fi
    fi
fi

echo -e "${YELLOW}🌱 Seeding database with test data...${NC}"
echo ""

# Insert test users
echo -e "${BLUE}👥 Creating test users...${NC}"
sqlite3 "$DB_PATH" << EOF
INSERT OR IGNORE INTO users (email, name) VALUES 
    ('alice@example.com', 'Alice Johnson'),
    ('bob@example.com', 'Bob Smith'),
    ('charlie@example.com', 'Charlie Brown'),
    ('diana@example.com', 'Diana Prince');
EOF

# Get user IDs for foreign key references
ALICE_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM users WHERE email = 'alice@example.com';")
BOB_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM users WHERE email = 'bob@example.com';")
CHARLIE_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM users WHERE email = 'charlie@example.com';")
DIANA_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM users WHERE email = 'diana@example.com';")

# Insert test calls
echo -e "${BLUE}📞 Creating test calls...${NC}"
sqlite3 "$DB_PATH" << EOF
INSERT OR IGNORE INTO calls (user_id, phone_number, recipient_context, objective, background_context, status) VALUES 
    ($ALICE_ID, '+1-555-0101', 'Pizza restaurant manager', 'Order a large pepperoni pizza for delivery', 'Hungry and want dinner delivered by 7 PM', 'pending'),
    ($BOB_ID, '+1-555-0102', 'Gym membership cancellation department', 'Cancel my gym membership', 'Moving to another city and cannot use this gym anymore', 'completed'),
    ($CHARLIE_ID, '+1-555-0103', 'Doctor office receptionist', 'Schedule annual checkup appointment', 'Need to schedule routine physical exam, prefer morning appointments', 'in_progress'),
    ($DIANA_ID, '+1-555-0104', 'Internet service provider support', 'Upgrade internet speed plan', 'Current plan is too slow for working from home', 'pending'),
    ($ALICE_ID, '+1-555-0105', 'Best friend Sarah', 'Share exciting news about job promotion', 'Just got promoted at work and want to share the good news', 'completed'),
    ($BOB_ID, '+1-555-0106', 'Bank customer service', 'Dispute fraudulent charge on credit card', 'Found unknown charge of \$200 on statement from last week', 'failed');
EOF

# Get call IDs for call logs
CALL_IDS=$(sqlite3 "$DB_PATH" "SELECT id FROM calls ORDER BY id;")

# Insert sample call logs for completed calls
echo -e "${BLUE}📝 Creating test call logs...${NC}"

# Call logs for completed gym membership cancellation
GYM_CALL_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM calls WHERE objective LIKE '%gym membership%';")
sqlite3 "$DB_PATH" << EOF
INSERT INTO call_logs (call_id, message_type, content) VALUES 
    ($GYM_CALL_ID, 'system', 'Call initiated to +1-555-0102'),
    ($GYM_CALL_ID, 'user_speech', 'Hello, I would like to cancel my gym membership please.'),
    ($GYM_CALL_ID, 'ai_response', 'Hi! I can help you with that. Can I get your membership number?'),
    ($GYM_CALL_ID, 'user_speech', 'Yes, it is GM-12345678'),
    ($GYM_CALL_ID, 'ai_response', 'Thank you. I see your account. May I ask the reason for cancellation?'),
    ($GYM_CALL_ID, 'user_speech', 'I am moving to another city and will not be able to use this location.'),
    ($GYM_CALL_ID, 'ai_response', 'I understand. I have processed your cancellation. You will receive a confirmation email.'),
    ($GYM_CALL_ID, 'system', 'Call completed successfully');
EOF

# Call logs for completed friend call
FRIEND_CALL_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM calls WHERE objective LIKE '%job promotion%';")
sqlite3 "$DB_PATH" << EOF
INSERT INTO call_logs (call_id, message_type, content) VALUES 
    ($FRIEND_CALL_ID, 'system', 'Call initiated to +1-555-0105'),
    ($FRIEND_CALL_ID, 'user_speech', 'Hey Sarah! I have some exciting news to share with you!'),
    ($FRIEND_CALL_ID, 'ai_response', 'Oh my gosh, what is it? You sound so excited!'),
    ($FRIEND_CALL_ID, 'user_speech', 'I just got promoted to Senior Developer at my company!'),
    ($FRIEND_CALL_ID, 'ai_response', 'That is amazing! Congratulations! I am so happy for you. We need to celebrate!'),
    ($FRIEND_CALL_ID, 'user_speech', 'Thank you! I am so thrilled. Let us plan something for this weekend.'),
    ($FRIEND_CALL_ID, 'ai_response', 'Absolutely! I will text you some ideas. So proud of you!'),
    ($FRIEND_CALL_ID, 'system', 'Call completed successfully');
EOF

echo ""
echo -e "${GREEN}✅ Database seeded successfully!${NC}"

# Show summary
echo ""
echo -e "${BLUE}📊 Seeding summary:${NC}"
sqlite3 "$DB_PATH" << EOF
.mode column
.headers on
.print "Data inserted:"
SELECT 
    'users' as table_name,
    COUNT(*) as total_records
FROM users
UNION ALL
SELECT 
    'calls' as table_name,
    COUNT(*) as total_records  
FROM calls
UNION ALL
SELECT 
    'call_logs' as table_name,
    COUNT(*) as total_records
FROM call_logs;
EOF

echo ""
echo -e "${YELLOW}📋 Test users created:${NC}"
sqlite3 "$DB_PATH" << EOF
.mode column
.headers on
SELECT id, name, email FROM users ORDER BY id;
EOF

echo ""
echo -e "${YELLOW}📞 Test calls created:${NC}"
sqlite3 "$DB_PATH" << EOF
.mode column
.headers on
SELECT 
    c.id,
    u.name as user,
    c.phone_number,
    substr(c.objective, 1, 50) || '...' as objective,
    c.status
FROM calls c
JOIN users u ON c.user_id = u.id
ORDER BY c.id;
EOF

echo ""
echo -e "${BLUE}💡 What was seeded:${NC}"
echo "  • 4 test users (Alice, Bob, Charlie, Diana)"
echo "  • 6 test calls with various objectives and statuses"
echo "  • Call logs for completed calls (conversation history)"
echo "  • Mix of pending, completed, in_progress, and failed calls"
echo ""

echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  • Run 'dev' to start the application and test with this data"
echo "  • Run 'test' to ensure tests pass with seeded data"
echo "  • Use 'db-status' to verify the data"
echo "" 