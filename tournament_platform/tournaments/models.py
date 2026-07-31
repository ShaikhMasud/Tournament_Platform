import uuid
from django.db import models
from django.conf import settings


# =============================================================================
# SPORTS MODULE
# =============================================================================

class Sport(models.Model):
    """Master list of sports supported by the platform."""
    
    name = models.CharField(max_length=100, unique=True)
    category = models.CharField(max_length=50)  # e.g., "Racket", "Team", "Individual"
    team_size = models.PositiveIntegerField(default=1)  # 1 for singles, 2 for doubles, etc.
    match_type = models.CharField(max_length=50)  # "singles", "doubles", "team"
    icon = models.CharField(max_length=50, blank=True)  # Icon name
    rules = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Sports"
        ordering = ['name']

    def __str__(self):
        return self.name


# =============================================================================
# TOURNAMENT MODULE
# =============================================================================

class Tournament(models.Model):
    """Complete tournament model with all required fields."""
    
    # Status choices
    STATUS_DRAFT = 'draft'
    STATUS_PUBLISHED = 'published'
    STATUS_REGISTRATION_OPEN = 'registration_open'
    STATUS_REGISTRATION_CLOSED = 'registration_closed'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_COMPLETED = 'completed'
    STATUS_CANCELLED = 'cancelled'
    STATUS_CHOICES = [
        (STATUS_DRAFT, 'Draft'),
        (STATUS_PUBLISHED, 'Published'),
        (STATUS_REGISTRATION_OPEN, 'Registration Open'),
        (STATUS_REGISTRATION_CLOSED, 'Registration Closed'),
        (STATUS_IN_PROGRESS, 'In Progress'),
        (STATUS_COMPLETED, 'Completed'),
        (STATUS_CANCELLED, 'Cancelled'),
    ]
    
    # Format choices
    FORMAT_KNOCKOUT = 'knockout'
    FORMAT_ROUND_ROBIN = 'round_robin'
    FORMAT_DOUBLE_ELIMINATION = 'double_elimination'
    FORMAT_LEAGUE = 'league'
    FORMAT_GROUP_STAGE = 'group_stage'
    FORMAT_SWISS = 'swiss'
    FORMAT_CHOICES = [
        (FORMAT_KNOCKOUT, 'Knockout'),
        (FORMAT_ROUND_ROBIN, 'Round Robin'),
        (FORMAT_DOUBLE_ELIMINATION, 'Double Elimination'),
        (FORMAT_LEAGUE, 'League'),
        (FORMAT_GROUP_STAGE, 'Group Stage'),
        (FORMAT_SWISS, 'Swiss System'),
    ]
    
    # Basic Info
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(
        "organizations.Organization", 
        on_delete=models.CASCADE, 
        related_name="tournaments"
    )
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Sport & Format
    sport = models.ForeignKey(Sport, on_delete=models.SET_NULL, null=True, blank=True)
    sport_name = models.CharField(max_length=50, default="badminton_single_game")  # Fallback
    tournament_type = models.CharField(max_length=50, default="singles")  # singles, doubles, team
    format = models.CharField(max_length=30, choices=FORMAT_CHOICES, default=FORMAT_KNOCKOUT)
    
    # Location
    location = models.CharField(max_length=255, blank=True)
    venue = models.CharField(max_length=200, blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    timezone = models.CharField(max_length=50, default='UTC')
    
    # Dates
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    registration_start = models.DateField(null=True, blank=True)
    registration_end = models.DateField(null=True, blank=True)
    
    # Participation Limits
    max_players = models.PositiveIntegerField(default=100)
    min_players = models.PositiveIntegerField(default=4)
    max_teams = models.PositiveIntegerField(default=0)  # For team events
    
    # Financial
    entry_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default='USD')
    prize_pool = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Media
    banner = models.URLField(blank=True)
    logo = models.URLField(blank=True)
    
    # Contact
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    website = models.URLField(blank=True)
    
    # Rules & Documents
    rules = models.TextField(blank=True)
    terms = models.TextField(blank=True)
    consent_form = models.TextField(blank=True)
    
    # Status & Visibility
    status = models.CharField(max_length=25, choices=STATUS_CHOICES, default=STATUS_DRAFT)
    is_public = models.BooleanField(default=False)
    visibility = models.CharField(max_length=20, default='public')  # public, private, unlisted
    
    # Metadata
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_tournaments'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['is_public']),
            models.Index(fields=['start_date']),
            models.Index(fields=['organization', 'status']),
        ]

    def __str__(self):
        return self.name
    
    @property
    def is_registration_open(self):
        from django.utils import timezone
        now = timezone.now().date()
        if self.registration_start and self.registration_end:
            return self.registration_start <= now <= self.registration_end
        return False


# =============================================================================
# CATEGORY MODULE
# =============================================================================

class Category(models.Model):
    """Tournament category (age group, skill level, etc.)."""
    
    KNOCKOUT = "knockout"
    ROUND_ROBIN = "round_robin"
    DOUBLE_ELIMINATION = "double_elimination"
    LEAGUE = "league"
    FORMAT_CHOICES = [
        (KNOCKOUT, "Knockout"),
        (ROUND_ROBIN, "Round Robin"),
        (DOUBLE_ELIMINATION, "Double Elimination"),
        (LEAGUE, "League"),
    ]
    
    OPEN = "open"
    REGISTRATION_OPEN = "registration_open"
    REGISTRATION_CLOSED = "registration_closed"
    DRAW_GENERATED = "draw_generated"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    STATUS_CHOICES = [
        (OPEN, "Open"),
        (REGISTRATION_OPEN, "Registration Open"),
        (REGISTRATION_CLOSED, "Registration Closed"),
        (DRAW_GENERATED, "Draw Generated"),
        (IN_PROGRESS, "In Progress"),
        (COMPLETED, "Completed"),
        (CANCELLED, "Cancelled"),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament, 
        on_delete=models.CASCADE, 
        related_name="categories"
    )
    
    # Basic Info
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    
    # Format & Capacity
    draw_format = models.CharField(max_length=20, choices=FORMAT_CHOICES, default=KNOCKOUT)
    capacity = models.PositiveIntegerField(default=32)
    min_capacity = models.PositiveIntegerField(default=4)
    
    # Age/Gender categories
    min_age = models.PositiveIntegerField(null=True, blank=True)
    max_age = models.PositiveIntegerField(null=True, blank=True)
    gender = models.CharField(max_length=20, blank=True)  # male, female, mixed, open
    
    # Status
    status = models.CharField(max_length=25, choices=STATUS_CHOICES, default=OPEN)
    
    # Fees for this category
    entry_fee = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Draw settings
    is_seeded = models.BooleanField(default=False)
    seed_count = models.PositiveIntegerField(default=0)
    is_drawn = models.BooleanField(default=False)
    is_locked = models.BooleanField(default=False)
    is_published = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tournament", "name"], name="uniq_category_name")
        ]
        verbose_name_plural = "Categories"
        ordering = ['name']

    def __str__(self):
        return f"{self.tournament.name} - {self.name}"


# =============================================================================
# VENUE MODULE
# =============================================================================

class Venue(models.Model):
    """Tournament venue/facility."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament, 
        on_delete=models.CASCADE, 
        related_name="venues"
    )
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    
    # Capacity
    total_capacity = models.PositiveIntegerField(default=0)
    viewing_capacity = models.PositiveIntegerField(default=0)
    
    # Facilities
    has_parking = models.BooleanField(default=False)
    has_cafe = models.BooleanField(default=False)
    has_wifi = models.BooleanField(default=False)
    is_indoor = models.BooleanField(default=True)
    is_accessible = models.BooleanField(default=True)
    
    # Contact
    contact_name = models.CharField(max_length=100, blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    contact_email = models.EmailField(blank=True)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.tournament.name} - {self.name}"


class Court(models.Model):
    """Court/field within a venue."""
    
    INDOOR = 'indoor'
    OUTDOOR = 'outdoor'
    SURFACE_CHOICES = [
        (INDOOR, 'Indoor'),
        (OUTDOOR, 'Outdoor'),
        ('hard', 'Hard Court'),
        ('clay', 'Clay'),
        ('grass', 'Grass'),
        ('synthetic', 'Synthetic'),
        ('carpet', 'Carpet'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    venue = models.ForeignKey(
        Venue, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name="courts"
    )
    tournament = models.ForeignKey(
        Tournament, 
        on_delete=models.CASCADE, 
        related_name="courts"
    )
    
    name = models.CharField(max_length=100)
    court_number = models.CharField(max_length=20, blank=True)
    surface = models.CharField(max_length=20, choices=SURFACE_CHOICES, default=INDOOR)
    
    # Capacity
    seating_capacity = models.PositiveIntegerField(default=50)
    
    # Availability
    is_active = models.BooleanField(default=True)
    is_available = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    
    # Scheduling
    opening_time = models.TimeField(null=True, blank=True)
    closing_time = models.TimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["tournament", "name"], 
                name="uniq_court_name"
            )
        ]
        ordering = ['name']

    def __str__(self):
        return f"{self.tournament.name} - {self.name}"


# =============================================================================
# TEAM MODULE
# =============================================================================

class Team(models.Model):
    """Team/club participating in tournaments."""
    
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    SUSPENDED = 'suspended'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
        (SUSPENDED, 'Suspended'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(
        "organizations.Organization",
        on_delete=models.CASCADE,
        related_name="teams",
        null=True,
        blank=True
    )
    tournament = models.ForeignKey(
        Tournament,
        on_delete=models.CASCADE,
        related_name="teams",
        null=True,
        blank=True
    )
    
    # Basic Info
    name = models.CharField(max_length=200)
    short_name = models.CharField(max_length=20, blank=True)
    description = models.TextField(blank=True)
    logo = models.URLField(blank=True)
    banner = models.URLField(blank=True)
    
    # Team Details
    captain = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="captained_teams"
    )
    coach = models.CharField(max_length=100, blank=True)
    manager = models.CharField(max_length=100, blank=True)
    
    # Contact
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    website = models.URLField(blank=True)
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    is_active = models.BooleanField(default=True)
    
    # Stats
    wins = models.PositiveIntegerField(default=0)
    losses = models.PositiveIntegerField(default=0)
    draws = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['tournament', 'status']),
        ]

    def __str__(self):
        return self.name


class TeamPlayer(models.Model):
    """Membership of players in teams."""
    
    ROLE_CAPTAIN = 'captain'
    ROLE_VICE_CAPTAIN = 'vice_captain'
    ROLE_PLAYER = 'player'
    ROLE_RESERVE = 'reserve'
    ROLE_COACH = 'coach'
    ROLE_MANAGER = 'manager'
    ROLE_OFFICIAL = 'official'
    ROLE_CHOICES = [
        (ROLE_CAPTAIN, 'Captain'),
        (ROLE_VICE_CAPTAIN, 'Vice Captain'),
        (ROLE_PLAYER, 'Player'),
        (ROLE_RESERVE, 'Reserve'),
        (ROLE_COACH, 'Coach'),
        (ROLE_MANAGER, 'Manager'),
        (ROLE_OFFICIAL, 'Official'),
    ]
    
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    INACTIVE = 'inactive'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
        (INACTIVE, 'Inactive'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name="members")
    player_profile = models.ForeignKey(
        "accounts.PlayerProfile",
        on_delete=models.CASCADE,
        related_name="team_memberships"
    )
    
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_PLAYER)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    jersey_number = models.CharField(max_length=10, blank=True)
    
    joined_at = models.DateField(auto_now_add=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    class Meta:
        unique_together = ['team', 'player_profile']
        ordering = ['role', 'player_profile__display_name']

    def __str__(self):
        return f"{self.team.name} - {self.player_profile.display_name}"


# =============================================================================
# OFFICIALS MODULE
# =============================================================================

class Official(models.Model):
    """Tournament officials (referees, umpires, scorers, etc.)."""
    
    TYPE_REFEREE = 'referee'
    TYPE_UMPIRE = 'umpire'
    TYPE_SCORER = 'scorer'
    TYPE_LINE_JUDGE = 'line_judge'
    TYPE_VOLUNTEER = 'volunteer'
    TYPE_DOCTOR = 'doctor'
    TYPE_PHYSIO = 'physio'
    TYPE_OTHER = 'other'
    TYPE_CHOICES = [
        (TYPE_REFEREE, 'Referee'),
        (TYPE_UMPIRE, 'Umpire'),
        (TYPE_SCORER, 'Scorer'),
        (TYPE_LINE_JUDGE, 'Line Judge'),
        (TYPE_VOLUNTEER, 'Volunteer'),
        (TYPE_DOCTOR, 'Doctor'),
        (TYPE_PHYSIO, 'Physiotherapist'),
        (TYPE_OTHER, 'Other'),
    ]
    
    PENDING = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'
    SUSPENDED = 'suspended'
    STATUS_CHOICES = [
        (PENDING, 'Pending'),
        (APPROVED, 'Approved'),
        (REJECTED, 'Rejected'),
        (SUSPENDED, 'Suspended'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament,
        on_delete=models.CASCADE,
        related_name="officials"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="official_roles",
        null=True,
        blank=True
    )
    
    # If not an existing user
    name = models.CharField(max_length=100, blank=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    
    official_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_UMPIRE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=PENDING)
    
    # Experience & Certification
    certification = models.CharField(max_length=100, blank=True)
    years_experience = models.PositiveIntegerField(default=0)
    notes = models.TextField(blank=True)
    
    assigned_matches = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['official_type', 'name']

    def __str__(self):
        name = self.user.get_full_name() if self.user else self.name
        return f"{name} ({self.get_official_type_display()})"


# =============================================================================
# REGISTRATION MODULE
# =============================================================================

class Registration(models.Model):
    """Player/team registration for tournaments."""
    
    STATUS_PENDING = 'pending'
    STATUS_APPROVED = 'approved'
    STATUS_REJECTED = 'rejected'
    STATUS_WAITLISTED = 'waitlisted'
    STATUS_WITHDRAWN = 'withdrawn'
    STATUS_CANCELLED = 'cancelled'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_APPROVED, 'Approved'),
        (STATUS_REJECTED, 'Rejected'),
        (STATUS_WAITLISTED, 'Waitlisted'),
        (STATUS_WITHDRAWN, 'Withdrawn'),
        (STATUS_CANCELLED, 'Cancelled'),
    ]
    
    TYPE_PLAYER = 'player'
    TYPE_TEAM = 'team'
    TYPE_CHOICES = [
        (TYPE_PLAYER, 'Player'),
        (TYPE_TEAM, 'Team'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament,
        on_delete=models.CASCADE,
        related_name="registrations"
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name="registrations",
        null=True,
        blank=True
    )
    
    registration_type = models.CharField(max_length=10, choices=TYPE_CHOICES, default=TYPE_PLAYER)
    
    # Player registration
    player_profile = models.ForeignKey(
        "accounts.PlayerProfile",
        on_delete=models.CASCADE,
        related_name="tournament_registrations",
        null=True,
        blank=True
    )
    
    # Team registration
    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="tournament_registrations",
        null=True,
        blank=True
    )
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    
    # Payment
    entry_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_paid = models.BooleanField(default=False)
    payment_id = models.CharField(max_length=100, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    
    # Approval
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_registrations"
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    registered_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Notes
    notes = models.TextField(blank=True)
    
    # Position in queue
    queue_position = models.PositiveIntegerField(null=True, blank=True)
    
    class Meta:
        ordering = ['-registered_at']
        indexes = [
            models.Index(fields=['tournament', 'status']),
            models.Index(fields=['player_profile', 'status']),
        ]

    def __str__(self):
        if self.player_profile:
            return f"{self.player_profile.display_name} - {self.tournament.name}"
        elif self.team:
            return f"{self.team.name} - {self.tournament.name}"
        return f"Registration {self.id}"


# =============================================================================
# NOTIFICATIONS MODULE
# =============================================================================

class Notification(models.Model):
    """Platform notifications."""
    
    TYPE_TOURNAMENT = 'tournament'
    TYPE_MATCH = 'match'
    TYPE_REGISTRATION = 'registration'
    TYPE_RESULT = 'result'
    TYPE_REMINDER = 'reminder'
    TYPE_SYSTEM = 'system'
    TYPE_CHOICES = [
        (TYPE_TOURNAMENT, 'Tournament'),
        (TYPE_MATCH, 'Match'),
        (TYPE_REGISTRATION, 'Registration'),
        (TYPE_RESULT, 'Result'),
        (TYPE_REMINDER, 'Reminder'),
        (TYPE_SYSTEM, 'System'),
    ]
    
    UNREAD = 'unread'
    READ = 'read'
    ARCHIVED = 'archived'
    STATUS_CHOICES = [
        (UNREAD, 'Unread'),
        (READ, 'Read'),
        (ARCHIVED, 'Archived'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications"
    )
    
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    
    # Related objects
    tournament = models.ForeignKey(
        Tournament,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notifications"
    )
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=UNREAD)
    
    # Actions
    action_url = models.URLField(blank=True)
    action_text = models.CharField(max_length=50, blank=True)
    
    # Metadata
    priority = models.CharField(max_length=10, default='normal')  # low, normal, high, urgent
    is_email_sent = models.BooleanField(default=False)
    is_push_sent = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['notification_type', 'created_at']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.title}"


# =============================================================================
# DOCUMENTS MODULE
# =============================================================================

class Document(models.Model):
    """Tournament documents (rule books, forms, etc.)."""
    
    TYPE_RULES = 'rules'
    TYPE_CONSENT = 'consent'
    TYPE_SCHEDULE = 'schedule'
    TYPE_RESULTS = 'results'
    TYPE_PHOTO = 'photo'
    TYPE_OTHER = 'other'
    TYPE_CHOICES = [
        (TYPE_RULES, 'Rule Book'),
        (TYPE_CONSENT, 'Consent Form'),
        (TYPE_SCHEDULE, 'Schedule'),
        (TYPE_RESULTS, 'Results'),
        (TYPE_PHOTO, 'Photo'),
        (TYPE_OTHER, 'Other'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.ForeignKey(
        Tournament,
        on_delete=models.CASCADE,
        related_name="documents"
    )
    
    title = models.CharField(max_length=200)
    document_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    description = models.TextField(blank=True)
    
    # File
    file = models.URLField(blank=True)
    file_name = models.CharField(max_length=255, blank=True)
    file_size = models.PositiveIntegerField(default=0)  # in bytes
    file_type = models.CharField(max_length=50, blank=True)  # mime type
    
    # Access
    is_public = models.BooleanField(default=False)
    requires_signature = models.BooleanField(default=False)
    is_mandatory = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['document_type', 'title']

    def __str__(self):
        return f"{self.tournament.name} - {self.title}"


# =============================================================================
# DOCUMENT SIGNATURES
# =============================================================================

class DocumentSignature(models.Model):
    """Track document sign-offs by participants."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    document = models.ForeignKey(
        Document,
        on_delete=models.CASCADE,
        related_name="signatures"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="document_signatures"
    )
    
    is_signed = models.BooleanField(default=False)
    signed_at = models.DateTimeField(null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=500, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['document', 'user']

    def __str__(self):
        return f"{self.user.email} - {self.document.title}"


# =============================================================================
# TOURNAMENT SETTINGS
# =============================================================================

class TournamentSettings(models.Model):
    """Tournament-specific settings and configuration."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.OneToOneField(
        Tournament,
        on_delete=models.CASCADE,
        related_name="settings"
    )
    
    # Scoring
    best_of_sets = models.PositiveIntegerField(default=3)
    points_per_set = models.PositiveIntegerField(default=21)
    tie_break_points = models.PositiveIntegerField(default=30)
    min_points_difference = models.PositiveIntegerField(default=2)
    enable_tie_break = models.BooleanField(default=True)
    
    # Timing
    warmup_time = models.PositiveIntegerField(default=5)  # minutes
    changeover_time = models.PositiveIntegerField(default=90)  # seconds
    tie_break_time = models.PositiveIntegerField(default=5)  # minutes
    injury_time = models.PositiveIntegerField(default=10)  # minutes
    
    # Rules
    enable_let = models.BooleanField(default=True)
    enable_advantage = models.BooleanField(default=True)
    max_consecutive_points = models.PositiveIntegerField(default=7)
    enable_pause = models.BooleanField(default=True)
    pause_duration = models.PositiveIntegerField(default=60)  # seconds
    
    # Display
    show_names = models.BooleanField(default=True)
    show_scores = models.BooleanField(default=True)
    enable_live_streaming = models.BooleanField(default=False)
    streaming_url = models.URLField(blank=True)
    
    # Awards
    enable_prizes = models.BooleanField(default=True)
    prize_details = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Settings - {self.tournament.name}"


# =============================================================================
# DASHBOARD STATISTICS (Computed)
# =============================================================================

class DashboardStats(models.Model):
    """Cached dashboard statistics for tournaments."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tournament = models.OneToOneField(
        Tournament,
        on_delete=models.CASCADE,
        related_name="stats"
    )
    
    # Counts
    total_registrations = models.PositiveIntegerField(default=0)
    approved_registrations = models.PositiveIntegerField(default=0)
    pending_registrations = models.PositiveIntegerField(default=0)
    total_teams = models.PositiveIntegerField(default=0)
    total_matches = models.PositiveIntegerField(default=0)
    completed_matches = models.PositiveIntegerField(default=0)
    total_courts = models.PositiveIntegerField(default=0)
    
    # Revenue
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    collected_fees = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # Computed at
    computed_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Stats - {self.tournament.name}"
